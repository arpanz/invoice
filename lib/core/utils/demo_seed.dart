import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/clients/models/client_model.dart';
import '../../features/dashboard/widgets/setup_checklist_card.dart';
import '../../features/estimates/models/estimate_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/invoices/models/line_item_model.dart';
import '../../features/invoices/models/payment_model.dart';
import '../../features/items/models/saved_item_model.dart';
import '../database/db_provider.dart';
import '../models/currency_model.dart';
import '../theme/theme_controller.dart';
import 'document_totals.dart';

/// Screenshot demo data for the store listing.
///
/// Active only in debug builds started with `--dart-define=DEMO_SEED=true`;
/// release and profile builds compile it out. When active it REPLACES all
/// local data on every launch with one small US design studio's working
/// month, marks onboarding done, turns Pro on (no watermark, no upsells) and
/// skips the store, update and review checks.
///
/// `--dart-define=DEMO_THEME=dark` starts the app in dark mode.
class DemoSeed {
  DemoSeed._();

  static const bool enabled =
      kDebugMode && bool.fromEnvironment('DEMO_SEED');

  static const String _theme = String.fromEnvironment('DEMO_THEME', defaultValue: 'light');

  static const _currency = 'USD';
  static const _taxRate = 8.0;

  /// Clears local data and writes the demo set. Call after the database
  /// opens and before anything reads preferences.
  static Future<void> run() async {
    if (!enabled) return;
    final prefs = await SharedPreferences.getInstance();
    await _seedPrefs(prefs);
    await _clearTables();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9, 41);
    DateTime daysAgo(int d) => today.subtract(Duration(days: d));

    final clients = <ClientModel>[
      ClientModel(id: 'seed-c1', name: 'Brightline Coffee Co.', email: 'hello@brightlinecoffee.com', phone: '(503) 555-0142', address: '1120 SE Division St, Portland, OR 97202', createdAt: daysAgo(80)),
      ClientModel(id: 'seed-c2', name: 'Meridian Dental Group', email: 'billing@meridiandental.com', phone: '(503) 555-0187', address: '415 NW 11th Ave, Portland, OR 97209', createdAt: daysAgo(74)),
      ClientModel(id: 'seed-c3', name: 'Oakridge Realty', email: 'ap@oakridgerealty.com', phone: '(971) 555-0110', address: '88 Oak St, Lake Oswego, OR 97034', createdAt: daysAgo(66)),
      ClientModel(id: 'seed-c4', name: 'Lumen Fitness', email: 'team@lumenfit.co', phone: '(503) 555-0163', address: '2301 N Williams Ave, Portland, OR 97227', createdAt: daysAgo(52)),
      ClientModel(id: 'seed-c5', name: 'Kestrel Labs', email: 'finance@kestrellabs.io', phone: '(206) 555-0198', address: '500 Union St, Seattle, WA 98101', createdAt: daysAgo(40)),
      ClientModel(id: 'seed-c6', name: 'Sunday Market Bakery', email: 'orders@sundaymarket.com', phone: '(503) 555-0129', address: '734 SE Hawthorne Blvd, Portland, OR 97214', createdAt: daysAgo(21)),
    ];
    for (final c in clients) {
      await DbProvider.saveClient(c);
    }
    ClientModel client(String id) => clients.firstWhere((c) => c.id == id);

    // Saved catalogue.
    final items = <SavedItemModel>[
      _item('seed-s1', 'Brand identity package', 2400, 'Branding', 'project', daysAgo(90)),
      _item('seed-s2', 'Logo design', 850, 'Branding', 'project', daysAgo(90)),
      _item('seed-s3', 'Website design (per page)', 450, 'Web', 'page', daysAgo(88)),
      _item('seed-s4', 'Landing page build', 1200, 'Web', 'project', daysAgo(85)),
      _item('seed-s5', 'Social media templates', 320, 'Marketing', 'set', daysAgo(70)),
      _item('seed-s6', 'Product photography', 95, 'Photo', 'hr', daysAgo(60)),
      _item('seed-s7', 'Design consultation', 120, 'Services', 'hr', daysAgo(60)),
      _item('seed-s8', 'Print collateral', 280, 'Marketing', 'set', daysAgo(45)),
    ];
    for (final i in items) {
      await DbProvider.insert(DbProvider.tableSavedItems, i.toMap());
    }

    // Invoices, newest first: number, client, issued, due in, lines,
    // discount %, payments (days ago, amount, method), sent.
    final invoices = [
      _Inv('INV-1048', 'seed-c1', 0, 30, [
        _L('Brand identity package', 1, 2400, 'project'),
        _L('Social media templates', 2, 320, 'set'),
        _L('Design consultation', 3, 120, 'hr'),
      ], pays: [], sent: false),
      _Inv('INV-1047', 'seed-c5', 12, 30, [
        _L('Landing page build', 1, 1200, 'project'),
        _L('Website design (per page)', 4, 450, 'page'),
      ], discount: 5, pays: [
        _P(10, 1000, 'Bank transfer', 'Deposit'),
        _P(3, 800, 'Card', 'Design sign-off'),
      ], sent: true),
      _Inv('INV-1046', 'seed-c2', 9, 15, [
        _L('Print collateral', 3, 280, 'set'),
        _L('Product photography', 6, 95, 'hr'),
      ], pays: [_P(2, 1522.80, 'Card', null)], sent: true),
      _Inv('INV-1045', 'seed-c3', 24, 15, [
        _L('Website design (per page)', 3, 450, 'page'),
        _L('Design consultation', 2, 120, 'hr'),
      ], pays: [], sent: true), // overdue
      _Inv('INV-1044', 'seed-c4', 28, 30, [
        _L('Logo design', 1, 850, 'project'),
        _L('Social media templates', 1, 320, 'set'),
      ], pays: [_P(12, 600, 'Zelle', 'First half'), _P(4, 663.60, 'Zelle', 'Balance')], sent: true),
      _Inv('INV-1043', 'seed-c6', 33, 30, [
        _L('Product photography', 8, 95, 'hr'),
        _L('Print collateral', 2, 280, 'set'),
      ], pays: [_P(20, 1425.60, 'Check', '#2087')], sent: true),
      _Inv('INV-1042', 'seed-c1', 45, 30, [
        _L('Logo design', 1, 850, 'project'),
      ], pays: [_P(38, 918, 'Card', null)], sent: true),
    ];

    for (final inv in invoices) {
      final c = client(inv.clientId);
      final id = 'seed-${inv.number.toLowerCase()}';
      final issued = daysAgo(inv.issuedDaysAgo);
      final lines = <LineItemModel>[
        for (var i = 0; i < inv.lines.length; i++)
          LineItemModel(
            id: '$id-l$i',
            invoiceId: id,
            description: inv.lines[i].description,
            quantity: inv.lines[i].qty,
            unitPrice: inv.lines[i].price,
            total: inv.lines[i].qty * inv.lines[i].price,
            sortOrder: i,
            unit: inv.lines[i].unit,
          ),
      ];
      final discountType = inv.discount > 0 ? DiscountType.percentage : DiscountType.none;
      final t = DocumentTotals.forCurrency(
        currencyCode: _currency,
        lines: lines,
        discountType: discountType,
        discountValue: inv.discount,
        igstRate: _taxRate,
      );
      await DbProvider.saveInvoice(InvoiceModel(
        id: id,
        invoiceNumber: inv.number,
        clientId: c.id,
        clientName: c.name,
        clientEmail: c.email,
        clientPhone: c.phone,
        clientAddress: c.address,
        invoiceDate: issued,
        dueDate: issued.add(Duration(days: inv.dueInDays)),
        subtotal: t.subtotal,
        discountType: discountType,
        discountValue: inv.discount,
        discountAmount: t.discountAmount,
        igstRate: _taxRate,
        taxAmount: t.taxAmount,
        grandTotal: t.grandTotal,
        notes: 'Thank you for your business! Payment due within ${inv.dueInDays} days.',
        currency: _currency,
        createdAt: issued,
        updatedAt: issued,
        lineItems: lines,
        sentAt: inv.sent ? issued.add(const Duration(hours: 2)) : null,
      ));
      for (var p = 0; p < inv.pays.length; p++) {
        final pay = inv.pays[p];
        final paidOn = daysAgo(pay.daysAgo);
        await DbProvider.addPayment(PaymentModel(
          id: '$id-p$p',
          invoiceId: id,
          // Never more than the total, whatever rounding did.
          amount: pay.amount > t.grandTotal ? t.grandTotal : pay.amount,
          paidOn: DateTime(paidOn.year, paidOn.month, paidOn.day),
          method: pay.method,
          note: pay.note,
          createdAt: paidOn,
        ));
      }
    }

    // Estimates.
    final estimates = [
      _Est('EST-0212', 'seed-c4', 1, [
        _L('Website design (per page)', 5, 450, 'page'),
        _L('Landing page build', 1, 1200, 'project'),
      ], EstimateStatus.pending),
      _Est('EST-0211', 'seed-c6', 6, [
        _L('Brand identity package', 1, 2400, 'project'),
      ], EstimateStatus.accepted),
      _Est('EST-0210', 'seed-c2', 15, [
        _L('Product photography', 10, 95, 'hr'),
        _L('Print collateral', 2, 280, 'set'),
      ], EstimateStatus.pending),
    ];
    for (final e in estimates) {
      final c = client(e.clientId);
      final id = 'seed-${e.number.toLowerCase()}';
      final issued = daysAgo(e.issuedDaysAgo);
      final lines = <LineItemModel>[
        for (var i = 0; i < e.lines.length; i++)
          LineItemModel(
            id: '$id-l$i',
            invoiceId: id,
            description: e.lines[i].description,
            quantity: e.lines[i].qty,
            unitPrice: e.lines[i].price,
            total: e.lines[i].qty * e.lines[i].price,
            sortOrder: i,
            unit: e.lines[i].unit,
          ),
      ];
      final t = DocumentTotals.forCurrency(currencyCode: _currency, lines: lines, igstRate: _taxRate);
      await DbProvider.saveEstimate(EstimateModel(
        id: id,
        estimateNumber: e.number,
        clientId: c.id,
        clientName: c.name,
        clientEmail: c.email,
        clientPhone: c.phone,
        clientAddress: c.address,
        estimateDate: issued,
        expiryDate: issued.add(const Duration(days: 30)),
        subtotal: t.subtotal,
        igstRate: _taxRate,
        taxAmount: t.taxAmount,
        grandTotal: t.grandTotal,
        status: e.status,
        currency: _currency,
        createdAt: issued,
        updatedAt: issued,
        lineItems: lines,
      ));
    }
  }

  static Future<void> _seedPrefs(SharedPreferences prefs) async {
    // Per-invoice designs from an earlier run would point at deleted rows.
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('invoice_customization_') || key.startsWith('invoice_theme_')) {
        await prefs.remove(key);
      }
    }
    final usd = SupportedCurrencies.getByCode(_currency)!;
    await prefs.setString('user_currency', jsonEncode(usd.toJson()));
    await prefs.setDouble('custom_default_tax_rate', _taxRate);
    await prefs.setBool('onboarding_complete', true);
    await prefs.setBool('is_premium_user', true);
    await prefs.setBool(SetupChecklist.dismissedKey, true);
    await prefs.setBool('legacy_mock_cleanup_v2_done', true);
    await prefs.setString(ThemeController.prefKey, _theme == 'dark' ? 'dark' : 'light');

    const profile = {
      'biz_name': 'Harbor & Pine Studio',
      'biz_tagline': 'Brand and web design',
      'biz_address': '1830 NW Lovejoy St, Portland, OR 97209',
      'biz_phone': '(503) 555-0176',
      'biz_email': 'studio@harborandpine.com',
      'biz_website': 'harborandpine.com',
      'biz_gstin': '93-4817265',
      'biz_bank_name': 'Pacific Coast Bank',
      'biz_account': '4417 2290 0183',
      'biz_ifsc': '123006800',
      'biz_notes': 'Payment due within 30 days. Thank you!',
    };
    for (final e in profile.entries) {
      await prefs.setString(e.key, e.value);
    }
    await prefs.remove('biz_upi');
    // Logo and signature pushed into <documents>/images by hand (see
    // docs/store/assets); left out when they aren't there.
    final images = '${(await getApplicationDocumentsDirectory()).path}/images';
    for (final kind in ['logo', 'signature']) {
      final file = File('$images/demo_$kind.png');
      if (await file.exists()) {
        await prefs.setString('biz_${kind}_path', file.path);
      } else {
        await prefs.remove('biz_${kind}_path');
      }
    }
  }

  static Future<void> _clearTables() async {
    for (final table in [
      DbProvider.tablePayments,
      DbProvider.tableLineItems,
      DbProvider.tableEstimateLineItems,
      DbProvider.tableInvoices,
      DbProvider.tableEstimates,
      DbProvider.tableSavedItems,
      DbProvider.tableClients,
    ]) {
      await DbProvider.execute('DELETE FROM $table');
    }
  }

  static SavedItemModel _item(String id, String name, double price, String category, String unit, DateTime at) =>
      SavedItemModel(
        id: id,
        name: name,
        unitPrice: price,
        unit: unit,
        category: category,
        taxRate: _taxRate,
        createdAt: at,
        updatedAt: at,
      );
}

class _L {
  final String description;
  final double qty;
  final double price;
  final String unit;
  const _L(this.description, this.qty, this.price, this.unit);
}

class _P {
  final int daysAgo;
  final double amount;
  final String method;
  final String? note;
  const _P(this.daysAgo, this.amount, this.method, this.note);
}

class _Inv {
  final String number;
  final String clientId;
  final int issuedDaysAgo;
  final int dueInDays;
  final List<_L> lines;
  final double discount;
  final List<_P> pays;
  final bool sent;
  const _Inv(this.number, this.clientId, this.issuedDaysAgo, this.dueInDays, this.lines,
      {this.discount = 0, required this.pays, required this.sent});
}

class _Est {
  final String number;
  final String clientId;
  final int issuedDaysAgo;
  final List<_L> lines;
  final EstimateStatus status;
  const _Est(this.number, this.clientId, this.issuedDaysAgo, this.lines, this.status);
}
