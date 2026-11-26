import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/export/csv_export_service.dart';
import 'package:invoice/features/clients/models/client_model.dart';
import 'package:invoice/features/estimates/models/estimate_model.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/payment_model.dart';
import 'package:invoice/features/items/models/saved_item_model.dart';
import 'package:invoice/features/reports/services/report_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('CsvExportService RFC 4180 quoting & BOM', () {
    test(
      'escapeField handles commas, quotes, newlines, null, and plain values',
      () {
        expect(CsvExportService.escapeField(null), '');
        expect(CsvExportService.escapeField('Simple'), 'Simple');
        expect(CsvExportService.escapeField('Acme, Inc.'), '"Acme, Inc."');
        expect(CsvExportService.escapeField('Say "Hello"'), '"Say ""Hello"""');
        expect(
          CsvExportService.escapeField('Line 1\nLine 2'),
          '"Line 1\nLine 2"',
        );
        expect(
          CsvExportService.escapeField('Line 1\r\nLine 2'),
          '"Line 1\r\nLine 2"',
        );
        expect(
          CsvExportService.escapeField('Quote "A", and\nnew line'),
          '"Quote ""A"", and\nnew line"',
        );
      },
    );

    test('encodeCsvWithBom prepends UTF-8 BOM and preserves ₹ symbol', () {
      final bytes = CsvExportService.encodeCsvWithBom([
        ['Item', 'Amount'],
        ['Design, "Pro"', '₹1,500'],
      ]);

      expect(bytes.sublist(0, 3), CsvExportService.utf8Bom);
      final decoded = utf8.decode(bytes.sublist(3));
      expect(decoded, 'Item,Amount\r\n"Design, ""Pro""","₹1,500"');
    });
  });

  group('CsvExportService headers, rows, and date filtering', () {
    final janInv = InvoiceModel(
      id: 'i1',
      invoiceNumber: 'INV00001',
      clientId: 'c1',
      clientName: 'Acme, Inc.',
      invoiceDate: DateTime(2026, 1, 15),
      dueDate: DateTime(2026, 1, 30),
      subtotal: 1000,
      sgstRate: 9,
      cgstRate: 9,
      taxAmount: 180,
      shipping: 50,
      grandTotal: 1230,
      paidAmount: 1230,
      status: InvoiceStatus.paid,
      currency: 'INR',
      createdAt: DateTime(2026, 1, 15),
      updatedAt: DateTime(2026, 1, 15),
      lineItems: [
        LineItemModel.create(
          id: 'li1',
          invoiceId: 'i1',
          description: 'Web "Design"\nPhase 1',
          quantity: 2,
          unitPrice: 500,
          hsnSac: '9983',
          unit: 'hrs',
        ),
      ],
    );

    final novInv = InvoiceModel(
      id: 'i2',
      invoiceNumber: 'INV00002',
      clientId: 'c1',
      clientName: 'Acme, Inc.',
      invoiceDate: DateTime(2026, 11, 10),
      dueDate: DateTime(2026, 11, 25),
      subtotal: 500,
      grandTotal: 500,
      paidAmount: 200,
      status: InvoiceStatus.partiallyPaid,
      currency: 'INR',
      createdAt: DateTime(2026, 11, 10),
      updatedAt: DateTime(2026, 11, 10),
      lineItems: [
        LineItemModel.create(
          id: 'li2',
          invoiceId: 'i2',
          description: 'Hosting',
          quantity: 1,
          unitPrice: 500,
        ),
      ],
    );

    final payments = [
      PaymentModel(
        id: 'p1',
        invoiceId: 'i1',
        amount: 1230,
        paidOn: DateTime(2026, 1, 20),
        method: 'UPI',
        note: 'Paid, thanks',
        createdAt: DateTime(2026, 1, 20),
      ),
      PaymentModel(
        id: 'p2',
        invoiceId: 'i2',
        amount: 200,
        paidOn: DateTime(2026, 11, 12),
        method: 'Bank',
        note: 'Part 1',
        createdAt: DateTime(2026, 11, 12),
      ),
    ];

    final clients = [
      ClientModel(
        id: 'c1',
        name: 'Acme, Inc.',
        email: 'billing@acme.test',
        phone: '+91 9876543210',
        address: '12 Main St\nMumbai',
        gstin: '27AAAAA0000A1Z5',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final savedItems = [
      SavedItemModel(
        id: 's1',
        name: 'Consultation',
        description: 'Hourly advisory',
        unitPrice: 1500,
        unit: 'hr',
        hsnCode: '9983',
        category: 'Services',
        isTaxable: true,
        taxRate: 18,
        discountRate: 0,
        defaultQuantity: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];

    final estimates = [
      EstimateModel(
        id: 'e1',
        estimateNumber: 'EST00001',
        clientId: 'c1',
        clientName: 'Acme, Inc.',
        estimateDate: DateTime(2026, 11, 1),
        expiryDate: DateTime(2026, 11, 15),
        subtotal: 2000,
        taxAmount: 360,
        igstRate: 18,
        grandTotal: 2360,
        status: EstimateStatus.accepted,
        notes: 'Valid for 15 days',
        currency: 'INR',
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        lineItems: [
          LineItemModel.create(
            id: 'el1',
            invoiceId: 'e1',
            description: 'App Build',
            quantity: 1,
            unitPrice: 2000,
          ),
        ],
      ),
    ];

    test('header rows match expected columns for all 6 tables', () {
      expect(CsvExportService.buildInvoicesRows([janInv]).first, [
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
      ]);
      expect(CsvExportService.buildLineItemsRows([janInv]).first, [
        'Invoice Number',
        'Description',
        'HSN/SAC',
        'Quantity',
        'Unit',
        'Unit Price',
        'Discount (%)',
        'Tax Rate (%)',
        'Amount',
      ]);
      expect(CsvExportService.buildPaymentsRows(payments, [janInv]).first, [
        'Invoice Number',
        'Payment Date',
        'Amount',
        'Method',
        'Note',
      ]);
      expect(CsvExportService.buildClientsRows(clients).first, [
        'Name',
        'Email',
        'Phone',
        'Address',
        'Tax ID',
        'Created Date',
      ]);
      expect(CsvExportService.buildSavedItemsRows(savedItems).first, [
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
      ]);
      expect(CsvExportService.buildEstimatesRows(estimates).first, [
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
      ]);
    });

    test(
      'writeCsvFiles writes all 6 files with BOM and respects date range on invoices/lines/payments',
      () async {
        final tmp = await Directory.systemTemp.createTemp('csv_export_test');
        addTearDown(() => tmp.delete(recursive: true));

        final novRange = ReportDateRange.forPeriod(
          ReportPeriod.thisMonth,
          now: DateTime(2026, 11, 26),
        );

        final files = await CsvExportService.writeCsvFiles(
          directory: tmp,
          invoices: [janInv, novInv],
          payments: payments,
          clients: clients,
          savedItems: savedItems,
          estimates: estimates,
          range: novRange,
        );

        expect(files.length, 6);
        expect(files.map((f) => f.uri.pathSegments.last).toList(), [
          'invoices.csv',
          'line_items.csv',
          'payments.csv',
          'clients.csv',
          'saved_items.csv',
          'estimates.csv',
        ]);

        for (final file in files) {
          final bytes = await file.readAsBytes();
          expect(bytes.sublist(0, 3), CsvExportService.utf8Bom);
        }

        final invoicesCsv = utf8.decode(
          (await files[0].readAsBytes()).sublist(3),
        );
        expect(invoicesCsv, contains('INV00002'));
        expect(invoicesCsv, isNot(contains('INV00001')));
        expect(invoicesCsv, contains('"Acme, Inc."'));

        final lineItemsCsv = utf8.decode(
          (await files[1].readAsBytes()).sublist(3),
        );
        expect(lineItemsCsv, contains('Hosting'));
        expect(lineItemsCsv, isNot(contains('Phase 1')));

        final paymentsCsv = utf8.decode(
          (await files[2].readAsBytes()).sublist(3),
        );
        expect(paymentsCsv, contains('INV00002,2026-11-12,200.00,Bank,Part 1'));
        expect(paymentsCsv, isNot(contains('INV00001')));

        final clientsCsv = utf8.decode(
          (await files[3].readAsBytes()).sublist(3),
        );
        expect(clientsCsv, contains('"12 Main St\nMumbai"'));

        final estimatesCsv = utf8.decode(
          (await files[5].readAsBytes()).sublist(3),
        );
        expect(
          estimatesCsv,
          contains(
            'EST00001,2026-11-01,2026-11-15,"Acme, Inc.",Accepted,2000.00,0.00,360.00,2360.00,INR,Valid for 15 days',
          ),
        );
      },
    );

    test(
      'exportFromDbToDirectory reads through DbProvider public API',
      () async {
        sqfliteFfiInit();
        final db = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: DbProvider.schemaVersion,
            singleInstance: false,
            onConfigure: DbProvider.configureForTesting,
            onCreate: DbProvider.createSchemaForTesting,
          ),
        );
        DbProvider.useDatabaseForTesting(db);
        final tmp = await Directory.systemTemp.createTemp('csv_db_test');
        addTearDown(() async {
          await db.close();
          await tmp.delete(recursive: true);
        });

        await DbProvider.saveClient(clients.first);
        await DbProvider.saveInvoice(janInv);
        await DbProvider.addPayment(payments.first);
        await DbProvider.insert(
          DbProvider.tableSavedItems,
          savedItems.first.toMap(),
        );
        await DbProvider.saveEstimate(estimates.first);

        final files = await CsvExportService.exportFromDbToDirectory(tmp);
        expect(files.length, 6);

        final invoicesCsv = utf8.decode(
          (await files[0].readAsBytes()).sublist(3),
        );
        expect(invoicesCsv, contains('INV00001'));
        final linesCsv = utf8.decode((await files[1].readAsBytes()).sublist(3));
        expect(linesCsv, contains('"Web ""Design""\nPhase 1"'));
      },
    );
  });

  test('formula-like text is neutralised but numbers are not', () {
    expect(CsvExportService.escapeField('=SUM(A1)'), "'=SUM(A1)");
    expect(CsvExportService.escapeField('@cmd'), "'@cmd");
    expect(CsvExportService.escapeField('-5.00'), '-5.00');
    expect(CsvExportService.escapeField('Acme'), 'Acme');
  });
}
