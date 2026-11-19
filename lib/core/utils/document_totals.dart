import '../../features/invoices/models/invoice_model.dart';
import '../../features/invoices/models/line_item_model.dart';
import '../models/currency_model.dart';

/// Which tax a [TaxComponent] is.
enum TaxComponentKind {
  /// Central GST (India, intra-state). Half of the full rate.
  cgst,

  /// State GST (India, intra-state). Half of the full rate.
  sgst,

  /// Integrated GST (India, inter-state). The full rate.
  igst,

  /// The single tax of a non-GST country (VAT, sales tax, ...).
  single,
}

/// One printed tax row, such as "CGST 9%".
class TaxComponent {
  final TaxComponentKind kind;

  /// Rate in percent for this row (for CGST/SGST, half the full rate).
  final double rate;

  /// Taxable value this row applies to.
  final double taxableAmount;

  /// Tax amount, rounded to the document's decimals.
  final double amount;

  const TaxComponent({
    required this.kind,
    required this.rate,
    required this.taxableAmount,
    required this.amount,
  });
}

/// The money figures of an invoice or estimate, computed in one place so the
/// editor, the stored row and every printed line always agree.
///
/// Rules:
/// - Each line's net amount is its [LineItemModel.total] (quantity × price
///   less the line discount).
/// - A document-level discount is shared across lines pro rata, which lowers
///   each line's taxable value (the GST treatment of a discount on the bill).
/// - A line with its own tax rate is taxed at that full rate; other lines use
///   the document rate. Under intra-state GST a full rate is split into equal
///   CGST and SGST halves; under IGST or a single-tax country it is one row.
/// - Every printed component is rounded to [decimals], and the grand total is
///   the sum of the rounded components, so the printed rows always add up.
class DocumentTotals {
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final List<TaxComponent> taxComponents;
  final double taxAmount;
  final double shipping;
  final double grandTotal;

  const DocumentTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxComponents,
    required this.taxAmount,
    required this.shipping,
    required this.grandTotal,
  });

  /// Computes the totals.
  ///
  /// [sgstRate]/[cgstRate] or [igstRate] are the document-level rates exactly
  /// as stored on the document (non-GST countries store their single rate in
  /// [igstRate]). [dualTaxCurrency] is true for GST (India), and decides
  /// whether a single rate prints as IGST or as the country's single tax.
  static DocumentTotals compute({
    required List<LineItemModel> lines,
    DiscountType discountType = DiscountType.none,
    double discountValue = 0,
    double sgstRate = 0,
    double cgstRate = 0,
    double igstRate = 0,
    bool dualTaxCurrency = false,
    double shipping = 0,
    int decimals = 2,
  }) {
    double r(double v) => roundTo(v, decimals);

    final rawSubtotal = lines.fold<double>(0, (sum, l) => sum + l.total);
    final subtotal = r(rawSubtotal);

    double discount;
    switch (discountType) {
      case DiscountType.percentage:
        discount = subtotal * discountValue / 100;
        break;
      case DiscountType.flat:
        discount = discountValue;
        break;
      case DiscountType.none:
        discount = 0;
        break;
    }
    discount = r(discount.clamp(0.0, subtotal < 0 ? 0.0 : subtotal).toDouble());
    final taxable = r(subtotal - discount);

    // Share of each line left after the document discount.
    final keep = rawSubtotal > 0 ? (1 - discount / rawSubtotal).clamp(0.0, 1.0) : 0.0;

    final singleMode = igstRate > 0 || (sgstRate <= 0 && cgstRate <= 0);
    final singleKind = dualTaxCurrency ? TaxComponentKind.igst : TaxComponentKind.single;

    // (kind, rate) → taxable value.
    final groups = <_GroupKey, double>{};
    void add(TaxComponentKind kind, double rate, double base) {
      if (rate <= 0 || base == 0) return;
      final key = _GroupKey(kind, rate);
      groups[key] = (groups[key] ?? 0) + base;
    }

    for (final line in lines) {
      final base = line.total * keep;
      final own = line.taxRate;
      if (own == null) {
        if (singleMode) {
          add(singleKind, igstRate, base);
        } else {
          add(TaxComponentKind.cgst, cgstRate, base);
          add(TaxComponentKind.sgst, sgstRate, base);
        }
      } else if (own > 0) {
        if (singleMode) {
          add(singleKind, own, base);
        } else {
          add(TaxComponentKind.cgst, own / 2, base);
          add(TaxComponentKind.sgst, own / 2, base);
        }
      }
    }

    final components = groups.entries
        .map((e) => TaxComponent(
              kind: e.key.kind,
              rate: e.key.rate,
              taxableAmount: r(e.value),
              amount: r(e.value * e.key.rate / 100),
            ))
        .toList()
      ..sort((a, b) {
        final byRate = a.rate.compareTo(b.rate);
        return byRate != 0 ? byRate : a.kind.index.compareTo(b.kind.index);
      });

    final tax = r(components.fold<double>(0, (s, c) => s + c.amount));
    final ship = r(shipping < 0 ? 0 : shipping);
    return DocumentTotals(
      subtotal: subtotal,
      discountAmount: discount,
      taxableAmount: taxable,
      taxComponents: components,
      taxAmount: tax,
      shipping: ship,
      grandTotal: r(taxable + tax + ship),
    );
  }

  /// [compute] with the tax style and decimals of [currencyCode].
  static DocumentTotals forCurrency({
    required String currencyCode,
    required List<LineItemModel> lines,
    DiscountType discountType = DiscountType.none,
    double discountValue = 0,
    double sgstRate = 0,
    double cgstRate = 0,
    double igstRate = 0,
    double shipping = 0,
  }) {
    final currency = SupportedCurrencies.getByCode(currencyCode);
    return compute(
      lines: lines,
      discountType: discountType,
      discountValue: discountValue,
      sgstRate: sgstRate,
      cgstRate: cgstRate,
      igstRate: igstRate,
      dualTaxCurrency: currency?.defaultTax.isDualTax ?? false,
      shipping: shipping,
      decimals: currency?.decimalPlaces ?? 2,
    );
  }

  /// Totals of a saved invoice.
  static DocumentTotals ofInvoice(InvoiceModel invoice) => forCurrency(
        currencyCode: invoice.currency,
        lines: invoice.lineItems,
        discountType: invoice.discountType,
        discountValue: invoice.discountValue,
        sgstRate: invoice.sgstRate,
        cgstRate: invoice.cgstRate,
        igstRate: invoice.igstRate,
        shipping: invoice.shipping,
      );

  /// Rounds half away from zero to [decimals] places.
  static double roundTo(double value, int decimals) {
    if (value.isNaN || value.isInfinite) return 0;
    var factor = 1.0;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    // A tiny nudge absorbs binary noise such as 1.005 being 1.00499999.
    final scaled = value * factor;
    final nudged = scaled + (scaled >= 0 ? 1e-7 : -1e-7);
    return nudged.round() / factor;
  }
}

class _GroupKey {
  final TaxComponentKind kind;
  final double rate;
  const _GroupKey(this.kind, this.rate);

  @override
  bool operator ==(Object other) =>
      other is _GroupKey && other.kind == kind && other.rate == rate;

  @override
  int get hashCode => Object.hash(kind, rate);
}
