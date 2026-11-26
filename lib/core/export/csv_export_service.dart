import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/clients/models/client_model.dart';
import '../../features/estimates/models/estimate_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/invoices/models/line_item_model.dart';
import '../../features/invoices/models/payment_model.dart';
import '../../features/items/models/saved_item_model.dart';
import '../../features/reports/services/report_service.dart';
import '../database/db_provider.dart';
import '../utils/document_totals.dart';
import '../utils/number_text.dart';

/// Writes RFC 4180 CSV files with a UTF-8 BOM (so Excel opens `₹` and other
/// Unicode symbols cleanly) and shares them via the system share sheet.
class CsvExportService {
  CsvExportService._();

  static const List<int> utf8Bom = [0xEF, 0xBB, 0xBF];

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  /// Escapes a single CSV field per RFC 4180:
  /// wraps in double quotes if it contains `,`, `"`, `\n`, or `\r`,
  /// and doubles internal `"` characters.
  static String escapeField(Object? value) {
    if (value == null) return '';
    var str = value.toString();
    // Text that starts like a formula would run as one in Excel/Sheets.
    // Numbers (e.g. "-5.00") are left alone.
    if (str.isNotEmpty && '=+-@\t\r'.contains(str[0]) && num.tryParse(str) == null) {
      str = "'$str";
    }
    final needsQuotes =
        str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r');
    if (!needsQuotes) return str;
    return '"${str.replaceAll('"', '""')}"';
  }

  /// Serializes [rows] into RFC 4180 CSV text with CRLF line endings.
  static String encodeRows(List<List<Object?>> rows) {
    return rows.map((row) => row.map(escapeField).join(',')).join('\r\n');
  }

  /// Encodes [rows] as UTF-8 bytes prefixed with the UTF-8 BOM.
  static Uint8List encodeCsvWithBom(List<List<Object?>> rows) {
    final csvBytes = utf8.encode(encodeRows(rows));
    return Uint8List.fromList([...utf8Bom, ...csvBytes]);
  }

  static String _moneyStr(double value) => value.toStringAsFixed(2);
  static String _dateStr(DateTime? d) => d == null ? '' : _dateFmt.format(d);

  static List<InvoiceModel> _filterInvoices(
    List<InvoiceModel> invoices,
    ReportDateRange? range,
  ) {
    if (range == null) return invoices;
    return invoices.where((i) => range.contains(i.invoiceDate)).toList();
  }

  static List<List<Object?>> buildInvoicesRows(
    List<InvoiceModel> invoices, {
    ReportDateRange? range,
  }) {
    final filtered = _filterInvoices(invoices, range);
    final rows = <List<Object?>>[
      const [
        'Invoice Number',
        'Invoice Date',
        'Due Date',
        'Client Name',
        'Status',
        'Subtotal',
        'Discount',
        'Tax',
        'Shipping',
        'Total',
        'Paid',
        'Balance',
        'Currency',
      ],
    ];

    for (final inv in filtered) {
      final totals = ReportService.totalsForInvoice(inv);
      final balance = (totals.grandTotal - inv.paidAmount).clamp(
        0.0,
        double.infinity,
      );
      rows.add([
        inv.invoiceNumber,
        _dateStr(inv.invoiceDate),
        _dateStr(inv.dueDate),
        inv.clientName,
        inv.effectiveStatus.label,
        _moneyStr(totals.subtotal),
        _moneyStr(totals.discountAmount),
        _moneyStr(totals.taxAmount),
        _moneyStr(totals.shipping),
        _moneyStr(totals.grandTotal),
        _moneyStr(inv.paidAmount),
        _moneyStr(balance),
        inv.currency,
      ]);
    }
    return rows;
  }

  static List<List<Object?>> buildLineItemsRows(
    List<InvoiceModel> invoices, {
    ReportDateRange? range,
  }) {
    final filtered = _filterInvoices(invoices, range);
    final rows = <List<Object?>>[
      const [
        'Invoice Number',
        'Description',
        'HSN/SAC',
        'Quantity',
        'Unit',
        'Unit Price',
        'Discount (%)',
        'Tax Rate (%)',
        'Amount',
      ],
    ];

    for (final inv in filtered) {
      final docTaxRate = inv.igstRate > 0
          ? inv.igstRate
          : (inv.sgstRate + inv.cgstRate);
      for (final line in inv.lineItems) {
        final effectiveTax = line.taxRate ?? docTaxRate;
        rows.add([
          inv.invoiceNumber,
          line.description,
          line.hsnSac ?? '',
          NumberText.trim(line.quantity),
          line.unit ?? '',
          _moneyStr(line.unitPrice),
          NumberText.trim(line.discountRate),
          NumberText.trim(effectiveTax),
          _moneyStr(line.total),
        ]);
      }
    }
    return rows;
  }

  static List<List<Object?>> buildPaymentsRows(
    List<PaymentModel> payments,
    List<InvoiceModel> invoices, {
    ReportDateRange? range,
  }) {
    final numberById = <String, String>{
      for (final inv in invoices) inv.id: inv.invoiceNumber,
    };
    final filtered = range == null
        ? payments
        : payments.where((p) => range.contains(p.paidOn)).toList();

    final rows = <List<Object?>>[
      const ['Invoice Number', 'Payment Date', 'Amount', 'Method', 'Note'],
    ];

    for (final p in filtered) {
      rows.add([
        numberById[p.invoiceId] ?? p.invoiceId,
        _dateStr(p.paidOn),
        _moneyStr(p.amount),
        p.method ?? '',
        p.note ?? '',
      ]);
    }
    return rows;
  }

  static List<List<Object?>> buildClientsRows(List<ClientModel> clients) {
    final rows = <List<Object?>>[
      const ['Name', 'Email', 'Phone', 'Address', 'Tax ID', 'Created Date'],
    ];

    for (final c in clients) {
      rows.add([
        c.name,
        c.email ?? '',
        c.phone ?? '',
        c.address ?? '',
        c.gstin ?? '',
        _dateStr(c.createdAt),
      ]);
    }
    return rows;
  }

  static List<List<Object?>> buildSavedItemsRows(List<SavedItemModel> items) {
    final rows = <List<Object?>>[
      const [
        'Name',
        'Description',
        'Category',
        'HSN/SAC',
        'Unit',
        'Default Qty',
        'Unit Price',
        'Discount (%)',
        'Taxable',
        'Tax Rate (%)',
      ],
    ];

    for (final item in items) {
      rows.add([
        item.name,
        item.description ?? '',
        item.category ?? '',
        item.hsnCode ?? '',
        item.unit,
        NumberText.trim(item.defaultQuantity),
        _moneyStr(item.unitPrice),
        NumberText.trim(item.discountRate),
        item.isTaxable ? 'Yes' : 'No',
        NumberText.trim(item.taxRate),
      ]);
    }
    return rows;
  }

  static List<List<Object?>> buildEstimatesRows(List<EstimateModel> estimates) {
    final rows = <List<Object?>>[
      const [
        'Estimate Number',
        'Estimate Date',
        'Expiry Date',
        'Client Name',
        'Status',
        'Subtotal',
        'Discount',
        'Tax',
        'Total',
        'Currency',
        'Notes',
      ],
    ];

    for (final est in estimates) {
      final totals = est.lineItems.isNotEmpty
          ? DocumentTotals.forCurrency(
              currencyCode: est.currency,
              lines: est.lineItems,
              discountType: est.discountType,
              discountValue: est.discountValue,
              sgstRate: est.sgstRate,
              cgstRate: est.cgstRate,
              igstRate: est.igstRate,
            )
          : null;
      rows.add([
        est.estimateNumber,
        _dateStr(est.estimateDate),
        _dateStr(est.expiryDate),
        est.clientName,
        est.status.label,
        _moneyStr(totals?.subtotal ?? est.subtotal),
        _moneyStr(totals?.discountAmount ?? est.discountAmount),
        _moneyStr(totals?.taxAmount ?? est.taxAmount),
        _moneyStr(totals?.grandTotal ?? est.grandTotal),
        est.currency,
        est.notes ?? '',
      ]);
    }
    return rows;
  }

  /// Writes all 6 CSV files into [directory] and returns the created [File]s.
  static Future<List<File>> writeCsvFiles({
    required Directory directory,
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
    required List<ClientModel> clients,
    required List<SavedItemModel> savedItems,
    required List<EstimateModel> estimates,
    ReportDateRange? range,
  }) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final filesSpec = <(String, List<List<Object?>>)>[
      ('invoices.csv', buildInvoicesRows(invoices, range: range)),
      ('line_items.csv', buildLineItemsRows(invoices, range: range)),
      ('payments.csv', buildPaymentsRows(payments, invoices, range: range)),
      ('clients.csv', buildClientsRows(clients)),
      ('saved_items.csv', buildSavedItemsRows(savedItems)),
      ('estimates.csv', buildEstimatesRows(estimates)),
    ];

    final out = <File>[];
    for (final (name, rows) in filesSpec) {
      final file = File('${directory.path}/$name');
      await file.writeAsBytes(encodeCsvWithBom(rows), flush: true);
      out.add(file);
    }
    return out;
  }

  /// Loads records from [DbProvider]'s public API and writes the 6 CSV files
  /// into [directory].
  static Future<List<File>> exportFromDbToDirectory(
    Directory directory, {
    ReportDateRange? range,
  }) async {
    final invoices = await DbProvider.loadInvoices();
    final paymentRows = await DbProvider.query(
      DbProvider.tablePayments,
      orderBy: 'paid_on ASC, created_at ASC',
    );
    final clientRows = await DbProvider.query(
      DbProvider.tableClients,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final savedItemRows = await DbProvider.query(
      DbProvider.tableSavedItems,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final estimateRows = await DbProvider.query(
      DbProvider.tableEstimates,
      orderBy: 'estimate_date DESC, estimate_number DESC',
    );
    final estimateLineRows = await DbProvider.query(
      DbProvider.tableEstimateLineItems,
      orderBy: 'sort_order ASC',
    );

    final linesByEstimate = <String, List<LineItemModel>>{};
    for (final r in estimateLineRows) {
      final line = LineItemModel.fromMap(r);
      linesByEstimate.putIfAbsent(line.invoiceId, () => []).add(line);
    }

    final estimates = [
      for (final r in estimateRows)
        EstimateModel.fromMap(r, items: linesByEstimate[r['id']] ?? const []),
    ];

    return writeCsvFiles(
      directory: directory,
      invoices: invoices,
      payments: paymentRows.map(PaymentModel.fromMap).toList(),
      clients: clientRows.map(ClientModel.fromMap).toList(),
      savedItems: savedItemRows.map(SavedItemModel.fromMap).toList(),
      estimates: estimates,
      range: range,
    );
  }

  /// Writes CSV files into a temporary subfolder and shares them together.
  static Future<void> exportAndShare({ReportDateRange? range}) async {
    final tempRoot = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final folder = Directory('${tempRoot.path}/csv_export_$stamp');
    final files = await exportFromDbToDirectory(folder, range: range);

    final rangeNote = range != null && range.period != ReportPeriod.allTime
        ? ' (${range.label})'
        : '';
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path, mimeType: 'text/csv')],
        text: 'Invoice Maker Pro CSV export$rangeNote',
      ),
    );
  }
}
