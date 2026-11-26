import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/features/clients/models/client_model.dart';
import 'package:invoice/features/estimates/models/estimate_model.dart';
import 'package:invoice/features/invoices/models/document_custom_field.dart';
import 'package:invoice/features/invoices/models/document_numbering.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/payment_model.dart';
import 'package:invoice/features/invoices/services/invoice_render_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

var _seq = 0;
String _id(String p) => '$p-${_seq++}';

InvoiceModel invoice(String number, {String? id, double price = 100, String? clientId}) {
  final invId = id ?? _id('inv');
  final now = DateTime(2026, 11, 1);
  return InvoiceModel(
    id: invId,
    invoiceNumber: number,
    clientId: clientId,
    clientName: 'Client',
    invoiceDate: now,
    subtotal: price,
    grandTotal: price,
    createdAt: now,
    updatedAt: now,
    lineItems: [
      LineItemModel.create(id: _id('li'), invoiceId: invId, description: 'Work', quantity: 1, unitPrice: price),
    ],
  );
}

EstimateModel estimate(String number, {String? clientId}) {
  final id = _id('est');
  final now = DateTime(2026, 11, 1);
  return EstimateModel(
    id: id,
    estimateNumber: number,
    clientId: clientId,
    clientName: 'Client',
    estimateDate: now,
    subtotal: 300,
    grandTotal: 300,
    createdAt: now,
    updatedAt: now,
    lineItems: [
      for (var i = 0; i < 3; i++)
        LineItemModel.create(id: _id('eli'), invoiceId: id, description: 'Item $i', quantity: 1, unitPrice: 100),
    ],
  );
}

Future<List<LineItemModel>> linesOf(Database db, String invoiceId) async =>
    (await db.query(DbProvider.tableLineItems, where: 'invoice_id = ?', whereArgs: [invoiceId]))
        .map(LineItemModel.fromMap)
        .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbProvider.schemaVersion,
        singleInstance: false,
        onConfigure: DbProvider.configureForTesting,
        onCreate: DbProvider.createSchemaForTesting,
      ),
    );
    DbProvider.useDatabaseForTesting(db);
  });

  tearDown(() async => db.close());

  test('F1: deleting a middle invoice never reuses an existing number', () async {
    final a = invoice('INV00001'), b = invoice('INV00002'), c = invoice('INV00003');
    for (final i in [a, b, c]) {
      await DbProvider.saveInvoice(i);
    }
    await DbProvider.deleteInvoice(b.id);
    expect(await DbProvider.getNextInvoiceNumber(), 'INV00004');
  });

  test('F1: numbering ignores the old epoch-based duplicate numbers', () async {
    await DbProvider.saveInvoice(invoice('INV00007'));
    await DbProvider.saveInvoice(invoice('INV483921'));
    expect(await DbProvider.getNextInvoiceNumber(), 'INV00008');
  });

  test('custom numbering honors width, start, and persisted settings', () async {
    const settings = DocumentNumbering(
      invoicePrefix: 'B2B/2026-27/',
      estimatePrefix: 'Q-',
      digits: 3,
      nextInvoice: 12,
      nextEstimate: 6,
    );
    await settings.save(await SharedPreferences.getInstance());
    await DbProvider.saveInvoice(invoice('INV00099'));
    await DbProvider.saveInvoice(invoice('B2B/2026-27/011'));
    await DbProvider.saveInvoice(invoice('B2B/2026-27/123456'));
    expect(await DbProvider.getNextInvoiceNumber(), 'B2B/2026-27/012');
    expect(await DbProvider.getNextEstimateNumber(), 'Q-006');
    final first = invoice('B2B/2026-27/014');
    await DbProvider.saveInvoice(first);
    final copy = await DbProvider.duplicateInvoice(
      first, newInvoiceId: 'custom-copy', newLineId: () => _id('line'),
    );
    expect(copy.invoiceNumber, 'B2B/2026-27/015');
    final quote = estimate('Q-006').copyWith(
      customFields: const [DocumentCustomField(label: 'PO Number', value: 'AB-12')],
    );
    await DbProvider.saveEstimate(quote);
    final converted = await DbProvider.convertEstimate(
      quote,
      (number) => quote.toInvoiceModel(newInvoiceId: 'converted', newInvoiceNumber: number),
      newId: () => _id('line'),
    );
    expect(converted.invoiceNumber, 'B2B/2026-27/016');
    expect(converted.customFields.single.value, 'AB-12');
    expect(await DbProvider.getNextEstimateNumber(), 'Q-007');
  });

  test('numbers escape literal prefixes and skip collisions beyond the width', () async {
    for (final number in ['X.%_+999', 'X.%_+1000', 'X.%_+1001', 'Xabc+888']) {
      await DbProvider.saveInvoice(invoice(number));
    }
    expect(
      await DbProvider.nextNumber(db, DbProvider.tableInvoices, 'invoice_number', 'X.%_+', digits: 3),
      'X.%_+1002',
    );
    expect(
      await DbProvider.nextNumber(db, DbProvider.tableInvoices, 'invoice_number', 'X.%_+', digits: 4),
      'X.%_+1002',
    );
    expect(
      await DbProvider.nextNumber(db, DbProvider.tableInvoices, 'invoice_number', 'Y-', digits: 8),
      'Y-00000001',
    );
    expect(DocumentNumbering.validPrefix('INV/2026-27/'), isTrue);
    expect(DocumentNumbering.validPrefix('X.%_+'), isFalse);
  });

  test('financial year rolls over on 1 April for new duplicates', () async {
    const settings = DocumentNumbering(addFinancialYear: true, digits: 3);
    await settings.save(await SharedPreferences.getInstance());
    final source = invoice('INV/2025-26/018');
    await DbProvider.saveInvoice(source);
    final march = await DbProvider.duplicateInvoice(
      source, newInvoiceId: 'march', newLineId: () => _id('line'), now: DateTime(2026, 3, 31),
    );
    final april = await DbProvider.duplicateInvoice(
      source, newInvoiceId: 'april', newLineId: () => _id('line'), now: DateTime(2026, 4, 1),
    );
    expect(march.invoiceNumber, 'INV/2025-26/019');
    expect(april.invoiceNumber, 'INV/2026-27/001');
    expect(settings.prefix(estimate: true, date: DateTime(2099, 4)), 'EST/2099-00/');
  });

  test('custom fields round trip through models and invoice duplication', () async {
    const fields = [
      DocumentCustomField(label: 'PO Number', value: 'PO-42'),
      DocumentCustomField(label: 'Vehicle No.'),
    ];
    final source = invoice('INV00001').copyWith(customFields: fields);
    final quote = estimate('EST00001').copyWith(customFields: fields);
    final stored = DocumentCustomField.encode(fields);
    expect(InvoiceModel.fromMap(source.toMap()).copyWith().toMap()['custom_fields'], stored);
    expect(EstimateModel.fromMap(quote.toMap()).copyWith().toMap()['custom_fields'], stored);
    expect(InvoiceModel.fromMap(source.toMap()..remove('custom_fields')).customFields, isEmpty);
    expect(DocumentCustomField.decode('broken JSON'), isEmpty);
    expect(DocumentCustomField.decode(DocumentCustomField.encode([...fields, ...fields, ...fields])), hasLength(5));
    await DbProvider.saveInvoice(source);
    final copy = await DbProvider.duplicateInvoice(
      source, newInvoiceId: 'field-copy', newLineId: () => _id('line'),
    );
    expect(copy.toMap()['custom_fields'], stored);
    expect((await DbProvider.loadInvoices()).map((invoice) => invoice.toMap()['custom_fields']), everyElement(stored));
  });

  test('default fields are label-only and recent labels are deduplicated', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      DocumentFieldPreferences.defaultsKey,
      '[{"label":"PO Number","value":"old value"}]',
    );
    expect(DocumentFieldPreferences.defaults(prefs).single.label, 'PO Number');
    expect(DocumentFieldPreferences.defaults(prefs).single.value, isEmpty);

    await DocumentFieldPreferences.remember(const [
      DocumentCustomField(label: 'PO Number'),
      DocumentCustomField(label: 'Vehicle No.'),
    ]);
    await DocumentFieldPreferences.remember(const [
      DocumentCustomField(label: 'vehicle no.'),
      DocumentCustomField(label: 'Project'),
    ]);
    expect(DocumentFieldPreferences.recent(prefs), ['vehicle no.', 'Project', 'PO Number']);
  });

  test('F1: a duplicate number is refused instead of overwriting', () async {
    final first = invoice('INV00001');
    await DbProvider.saveInvoice(first);
    await expectLater(
      DbProvider.saveInvoice(invoice('INV00001')),
      throwsA(isA<DuplicateNumberException>()),
    );
    final rows = await db.query(DbProvider.tableInvoices);
    expect(rows.single['id'], first.id);
    expect((await linesOf(db, first.id)).length, 1);
  });

  test('editing an invoice keeps its lines (update, not replace)', () async {
    final inv = invoice('INV00001');
    await DbProvider.saveInvoice(inv);
    await DbProvider.saveInvoice(inv.copyWith(clientName: 'Renamed'));
    final rows = await db.query(DbProvider.tableInvoices);
    expect(rows.single['client_name'], 'Renamed');
    expect((await linesOf(db, inv.id)).length, 1);
  });

  test('F47: estimates round-trip through the database', () async {
    final est = estimate('EST00001');
    await DbProvider.saveEstimate(est);
    final rows = await db.query(DbProvider.tableEstimateLineItems,
        where: 'estimate_id = ?', whereArgs: [est.id]);
    final lines = rows.map(LineItemModel.fromMap).toList();
    expect(lines.length, 3);
    expect(lines.first.invoiceId, est.id);
  });

  test('F49: converting twice is refused and the first invoice keeps its lines', () async {
    final est = estimate('EST00001');
    await DbProvider.saveEstimate(est);
    InvoiceModel build(String n) => invoice(n, price: 300).copyWith(lineItems: est.lineItems);
    final first = await DbProvider.convertEstimate(est, build, newId: () => _id('new'));
    expect(first.invoiceNumber, 'INV00001');
    expect((await linesOf(db, first.id)).length, 3);
    // The converted lines are new rows, not the estimate's ids.
    expect((await linesOf(db, first.id)).map((l) => l.id).toSet().intersection(est.lineItems.map((l) => l.id).toSet()),
        isEmpty);

    // Even if the status is flipped back, the stored link blocks a re-convert.
    await db.update(DbProvider.tableEstimates, {'status': 'accepted'}, where: 'id = ?', whereArgs: [est.id]);
    await expectLater(
      DbProvider.convertEstimate(est, build, newId: () => _id('new')),
      throwsA(isA<AlreadyConvertedException>()),
    );
    expect((await linesOf(db, first.id)).length, 3);
  });

  test('deleting a converted invoice lets its estimate be converted again', () async {
    final est = estimate('EST00001');
    await DbProvider.saveEstimate(est);
    InvoiceModel build(String n) => invoice(n, price: 300).copyWith(lineItems: est.lineItems);
    final first = await DbProvider.convertEstimate(est, build, newId: () => _id('new'));
    await DbProvider.deleteInvoice(first.id);
    final row = (await db.query(DbProvider.tableEstimates, where: 'id = ?', whereArgs: [est.id])).single;
    expect(row['converted_invoice_id'], isNull);
    expect(row['status'], EstimateStatus.accepted.value);
    final again = await DbProvider.convertEstimate(est, build, newId: () => _id('new'));
    expect((await linesOf(db, again.id)).length, 3);
  });

  test('F52: re-saving an estimate from a stale editor keeps its conversion', () async {
    final est = estimate('EST00001');
    await DbProvider.saveEstimate(est);
    InvoiceModel build(String n) => invoice(n, price: 300).copyWith(lineItems: est.lineItems);
    final inv = await DbProvider.convertEstimate(est, build, newId: () => _id('new'));
    // The editor still holds the pre-conversion model (status pending, no link).
    await DbProvider.saveEstimate(est.copyWith(clientName: 'Edited'));
    final row = (await db.query(DbProvider.tableEstimates, where: 'id = ?', whereArgs: [est.id])).single;
    expect(row['client_name'], 'Edited');
    expect(row['status'], EstimateStatus.converted.value);
    expect(row['converted_invoice_id'], inv.id);
  });

  test('F19: sent time and issuer snapshot are stored on the invoice', () async {
    final sent = DateTime(2026, 11, 2, 10, 30);
    final inv = invoice('INV00001').copyWith(sentAt: sent, issuerSnapshot: '{"businessName":"Acme"}');
    await DbProvider.saveInvoice(inv);
    final row = (await db.query(DbProvider.tableInvoices)).single;
    final back = InvoiceModel.fromMap(row, items: const []);
    expect(back.sentAt, sent);
    expect(back.issuerSnapshot, contains('Acme'));
  });

  test('F18: duplicate is an unpaid draft with the next number and new line ids', () async {
    final paid = invoice('INV00001').copyWith(paidAmount: 100, status: InvoiceStatus.paid);
    await DbProvider.saveInvoice(paid);
    final copy = await DbProvider.duplicateInvoice(paid,
        newInvoiceId: 'copy', newLineId: () => _id('cl'), now: DateTime(2026, 11, 19));
    expect(copy.invoiceNumber, 'INV00002');
    expect(copy.paidAmount, 0);
    expect(copy.status, InvoiceStatus.unpaid);
    expect(copy.invoiceDate, DateTime(2026, 11, 19));
    expect((await linesOf(db, 'copy')).single.id, isNot(paid.lineItems.single.id));
    expect((await linesOf(db, paid.id)).length, 1);
  });

  test('F11: deleting a client with invoices works with foreign keys on', () async {
    final client = ClientModel(id: 'c1', name: 'Acme', createdAt: DateTime(2026));
    await DbProvider.saveClient(client);
    final inv = invoice('INV00001', clientId: 'c1');
    await DbProvider.saveInvoice(inv);
    await DbProvider.deleteClient('c1');
    final row = (await db.query(DbProvider.tableInvoices)).single;
    expect(row['client_id'], isNull);
    expect(row['client_name'], 'Client');
  });

  test('F11: deleting an invoice removes its lines', () async {
    final inv = invoice('INV00001');
    await DbProvider.saveInvoice(inv);
    await DbProvider.deleteInvoice(inv.id);
    expect(await db.query(DbProvider.tableLineItems), isEmpty);
  });

  test('new line columns round-trip', () async {
    final inv = invoice('INV00001').copyWith(lineItems: [
      LineItemModel.create(
        id: 'x', invoiceId: 'ignored', description: 'Cement', quantity: 2, unitPrice: 400,
        discountRate: 5, taxRate: 28, hsnSac: '2523', unit: 'bag',
      ),
    ]);
    await DbProvider.saveInvoice(inv);
    final l = (await linesOf(db, inv.id)).single;
    expect([l.discountRate, l.taxRate, l.hsnSac, l.unit, l.total], [5, 28, '2523', 'bag', 760]);
  });

  group('payments', () {
    PaymentModel pay(String invoiceId, double amount) => PaymentModel(
          id: _id('pay'),
          invoiceId: invoiceId,
          amount: amount,
          paidOn: DateTime(2026, 11, 2),
          createdAt: DateTime(2026, 11, 2),
        );

    Future<InvoiceModel> load(String id) async =>
        InvoiceModel.fromMap((await db.query(DbProvider.tableInvoices, where: 'id = ?', whereArgs: [id])).single);

    test('payments add up; paid amount and status follow them', () async {
      final inv = invoice('INV00001', price: 1000);
      await DbProvider.saveInvoice(inv);
      await DbProvider.addPayment(pay(inv.id, 300));
      await DbProvider.addPayment(pay(inv.id, 200));
      var stored = await load(inv.id);
      expect(stored.paidAmount, 500);
      expect(stored.status, InvoiceStatus.partiallyPaid);

      await DbProvider.markPaidInFull(inv.id);
      stored = await load(inv.id);
      expect(stored.paidAmount, 1000);
      expect(stored.status, InvoiceStatus.paid);
      expect((await DbProvider.paymentsFor(inv.id)).map((p) => p.amount), [300, 200, 500]);

      final first = (await DbProvider.paymentsFor(inv.id)).first;
      await DbProvider.deletePayment(first.id);
      expect((await load(inv.id)).paidAmount, 700);

      await DbProvider.clearPayments(inv.id);
      stored = await load(inv.id);
      expect(stored.paidAmount, 0);
      expect(stored.status, InvoiceStatus.unpaid);
    });

    test('swipe-to-paid Undo: markPaidInFull returns the new payment, deleting it restores the invoice', () async {
      final inv = invoice('INV00001', price: 1000);
      await DbProvider.saveInvoice(inv);
      await DbProvider.addPayment(pay(inv.id, 300));

      final paymentId = await DbProvider.markPaidInFull(inv.id);
      expect(paymentId, isNotNull);
      expect((await load(inv.id)).status, InvoiceStatus.paid);
      final added = (await DbProvider.paymentsFor(inv.id)).singleWhere((p) => p.id == paymentId);
      expect(added.amount, 700);

      // Undo removes exactly that payment and the earlier one stays.
      await DbProvider.deletePayment(paymentId!);
      final stored = await load(inv.id);
      expect(stored.paidAmount, 300);
      expect(stored.status, InvoiceStatus.partiallyPaid);
      expect((await DbProvider.paymentsFor(inv.id)).map((p) => p.amount), [300]);

      // Nothing owed: no payment is made and no id comes back.
      await DbProvider.markPaidInFull(inv.id);
      expect(await DbProvider.markPaidInFull(inv.id), isNull);
    });

    test('an editor save never overwrites recorded payments', () async {
      final inv = invoice('INV00001', price: 1000);
      await DbProvider.saveInvoice(inv);
      await DbProvider.addPayment(pay(inv.id, 400));
      // A stale editor still thinks nothing was paid, and the total changed.
      await DbProvider.saveInvoice(inv.copyWith(paidAmount: 0, grandTotal: 400, status: InvoiceStatus.unpaid));
      final stored = await load(inv.id);
      expect(stored.paidAmount, 400);
      expect(stored.status, InvoiceStatus.paid, reason: 'the new total is covered');
    });

    test('a new invoice saved with money received gets one payment', () async {
      final inv = invoice('INV00001', price: 1000).copyWith(paidAmount: 250);
      await DbProvider.saveInvoice(inv);
      expect((await DbProvider.paymentsFor(inv.id)).single.amount, 250);
      expect((await load(inv.id)).status, InvoiceStatus.partiallyPaid);
    });

    test('a paid invoice stamp uses the latest payment date', () async {
      final inv = invoice('INV00001');
      await DbProvider.saveInvoice(inv);
      final earlier = DateTime(2026, 11, 2);
      final latest = DateTime(2026, 11, 4);
      await DbProvider.addPayment(PaymentModel(
        id: _id('p'),
        invoiceId: inv.id,
        amount: 55,
        paidOn: latest,
        createdAt: latest,
      ));
      expect(await InvoiceRenderService.lastPaymentDate(await load(inv.id)), isNull);
      await DbProvider.addPayment(PaymentModel(
        id: _id('p'),
        invoiceId: inv.id,
        amount: 45,
        paidOn: earlier,
        createdAt: latest.add(const Duration(days: 1)),
      ));
      expect(await InvoiceRenderService.lastPaymentDate(await load(inv.id)), latest);
    });

    test('deleting an invoice deletes its payments', () async {
      final inv = invoice('INV00001');
      await DbProvider.saveInvoice(inv);
      await DbProvider.addPayment(pay(inv.id, 50));
      await DbProvider.deleteInvoice(inv.id);
      expect(await db.query(DbProvider.tablePayments), isEmpty);
    });

    test('v5 → v6 turns each paid amount into one payment; safe to rerun', () async {
      await db.execute('DROP TABLE ${DbProvider.tablePayments}');
      final paid = invoice('INV00001', price: 1000), part = invoice('INV00002', price: 1000), none = invoice('INV00003');
      for (final i in [paid, part, none]) {
        await db.insert(DbProvider.tableInvoices, i.toMap());
      }
      await db.update(DbProvider.tableInvoices, {'paid_amount': 1000, 'status': 'paid'}, where: 'id = ?', whereArgs: [paid.id]);
      await db.update(DbProvider.tableInvoices, {'paid_amount': 333.33}, where: 'id = ?', whereArgs: [part.id]);

      await DbProvider.upgradeForTesting(db, 5, 6);
      await DbProvider.upgradeForTesting(db, 5, 6);

      final rows = await db.query(DbProvider.tablePayments, orderBy: 'amount DESC');
      expect(rows.map((r) => r['amount']), [1000, 333.33]);
      expect(rows.map((r) => r['invoice_id']), [paid.id, part.id]);
    });
  });

  test('v6 → v7 adds attachment storage and preserves existing invoices', () async {
    final directory = await Directory.systemTemp.createTemp('invoice_upgrade');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/invoices.db';
    final original = invoice('INV00042');
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onConfigure: DbProvider.configureForTesting,
        onCreate: (db, version) async {
          await DbProvider.createSchemaForTesting(db, version);
          await db.execute('ALTER TABLE invoices DROP COLUMN attachments');
          await db.execute('ALTER TABLE invoices DROP COLUMN custom_fields');
          await db.execute('ALTER TABLE estimates DROP COLUMN custom_fields');
        },
      ),
    );
    await old.insert(DbProvider.tableInvoices, original.toMap()..remove('attachments')..remove('custom_fields'));
    await old.close();

    final upgraded = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onConfigure: DbProvider.configureForTesting,
        onUpgrade: DbProvider.upgradeForTesting,
      ),
    );
    addTearDown(upgraded.close);
    final row = (await upgraded.query(DbProvider.tableInvoices)).single;
    expect(await upgraded.getVersion(), 7);
    expect(row.containsKey('attachments'), isTrue);
    expect(InvoiceModel.fromMap(row).attachments, isEmpty);
    expect(row['invoice_number'], original.invoiceNumber);
    await DbProvider.upgradeForTesting(upgraded, 6, 7);
  });

  test('v7 → v8 adds custom fields and preserves both document numbers', () async {
    final directory = await Directory.systemTemp.createTemp('invoice_fields_upgrade');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/invoices.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (db, version) async {
          await DbProvider.createSchemaForTesting(db, version);
          for (final table in [DbProvider.tableInvoices, DbProvider.tableEstimates]) {
            await db.execute('ALTER TABLE $table DROP COLUMN custom_fields');
          }
        },
      ),
    );
    await old.insert(DbProvider.tableInvoices, invoice('INV00042').toMap()..remove('custom_fields'));
    await old.insert(DbProvider.tableEstimates, estimate('EST00056').toMap()..remove('custom_fields'));
    await old.close();

    final upgraded = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DbProvider.schemaVersion,
        onConfigure: DbProvider.configureForTesting,
        onUpgrade: DbProvider.upgradeForTesting,
      ),
    );
    addTearDown(upgraded.close);
    expect(await upgraded.getVersion(), 8);
    await DbProvider.upgradeForTesting(upgraded, 7, 8);
    final inv = (await upgraded.query(DbProvider.tableInvoices)).single;
    final quote = (await upgraded.query(DbProvider.tableEstimates)).single;
    expect(inv['invoice_number'], 'INV00042');
    expect(quote['estimate_number'], 'EST00056');
    expect(inv, containsPair('custom_fields', null));
    expect(quote, containsPair('custom_fields', null));
    expect(InvoiceModel.fromMap(inv).customFields, isEmpty);
    expect(EstimateModel.fromMap(quote).customFields, isEmpty);
  });

  test('duplicate retains photos and deletion removes the last reference', () async {
    final directory = await Directory.systemTemp.createTemp('invoice_attachments');
    addTearDown(() => directory.delete(recursive: true));
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async {
      expect(call.method, 'getApplicationDocumentsDirectory');
      return directory.path;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(pathProvider, null));

    final images = await Directory('${directory.path}/images').create();
    final photo = await File('${images.path}/attachment_test.jpg').writeAsBytes([1, 2, 3]);
    final original = invoice('INV00001').copyWith(attachments: [photo.path]);
    await DbProvider.saveInvoice(original);
    final duplicate = await DbProvider.duplicateInvoice(
      original,
      newInvoiceId: _id('inv'),
      newLineId: () => _id('li'),
    );
    expect(duplicate.attachments, [photo.path]);
    expect((await DbProvider.loadInvoices()).every((row) => row.attachments.single == photo.path), isTrue);

    await DbProvider.deleteInvoice(original.id);
    expect(await photo.exists(), isTrue);
    await DbProvider.deleteInvoice(duplicate.id);
    expect(await photo.exists(), isFalse);
  });

  group('v4 → v5 upgrade', () {
    late Database old;

    setUp(() async {
      old = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await old.execute('CREATE TABLE clients (id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT, phone TEXT, address TEXT, gstin TEXT, created_at INTEGER NOT NULL)');
      await old.execute('''CREATE TABLE invoices (id TEXT PRIMARY KEY, invoice_number TEXT NOT NULL UNIQUE, client_id TEXT,
        client_name TEXT NOT NULL, client_email TEXT, client_phone TEXT, client_address TEXT, client_gstin TEXT,
        invoice_date INTEGER NOT NULL, due_date INTEGER, subtotal REAL NOT NULL DEFAULT 0, discount_type TEXT DEFAULT 'none',
        discount_value REAL DEFAULT 0, discount_amount REAL DEFAULT 0, sgst_rate REAL DEFAULT 0, cgst_rate REAL DEFAULT 0,
        igst_rate REAL DEFAULT 0, tax_amount REAL DEFAULT 0, grand_total REAL NOT NULL DEFAULT 0, paid_amount REAL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'unpaid', notes TEXT, currency TEXT DEFAULT 'INR', created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL, FOREIGN KEY (client_id) REFERENCES clients(id))''');
      await old.execute('''CREATE TABLE line_items (id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, description TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1, unit_price REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE)''');
      await old.execute('''CREATE TABLE estimates (id TEXT PRIMARY KEY, estimate_number TEXT NOT NULL UNIQUE, client_id TEXT,
        client_name TEXT NOT NULL, client_email TEXT, client_phone TEXT, client_address TEXT, client_gstin TEXT,
        estimate_date INTEGER NOT NULL, expiry_date INTEGER, subtotal REAL NOT NULL DEFAULT 0, discount_type TEXT DEFAULT 'none',
        discount_value REAL DEFAULT 0, discount_amount REAL DEFAULT 0, sgst_rate REAL DEFAULT 0, cgst_rate REAL DEFAULT 0,
        igst_rate REAL DEFAULT 0, tax_amount REAL DEFAULT 0, grand_total REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending',
        converted_invoice_id TEXT, notes TEXT, currency TEXT DEFAULT 'INR', created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id))''');
      await old.execute('''CREATE TABLE estimate_line_items (id TEXT PRIMARY KEY, estimate_id TEXT NOT NULL, description TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1, unit_price REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (estimate_id) REFERENCES estimates(id) ON DELETE CASCADE)''');
      await old.execute('CREATE TABLE saved_items (id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');

      // Data written while foreign keys were off.
      Map<String, Object?> inv(String id, String n, {double sub = 100, double disc = 0, double tax = 0, double total = 100, String? client}) => {
            'id': id, 'invoice_number': n, 'client_id': client, 'client_name': 'C', 'invoice_date': 0,
            'subtotal': sub, 'discount_amount': disc, 'tax_amount': tax, 'grand_total': total, 'created_at': 0, 'updated_at': 0,
          };
      await old.insert('invoices', inv('a', 'INV00001', sub: 1000, tax: 180, total: 1230)); // 50 shipping
      await old.insert('invoices', inv('b', 'INV00002', sub: 300, disc: 500, total: 0)); // flat discount > subtotal
      await old.insert('invoices', inv('c', 'INV00003', client: 'deleted-client'));
      await old.insert('invoices', {...inv('d', 'INV00004', total: 250), 'status': 'paid', 'paid_amount': 0});
      await old.insert('line_items', {'id': 'orphan', 'invoice_id': 'gone', 'description': 'x'});
      await old.insert('line_items', {'id': 'kept', 'invoice_id': 'a', 'description': 'x', 'total': 1000});
    });

    tearDown(() async => old.close());

    test('adds columns, recovers shipping, repairs bad references; safe to rerun', () async {
      await DbProvider.upgradeForTesting(old, 4, 5);
      await DbProvider.upgradeForTesting(old, 4, 5); // idempotent

      final rows = {for (final r in await old.query('invoices')) r['id']: r};
      expect(rows['a']!['shipping'], 50);
      expect(rows['b']!['shipping'], 0, reason: 'must not invent shipping from an unclamped discount');
      expect(rows['c']!['client_id'], isNull);
      expect(rows['d']!['paid_amount'], 250, reason: 'paid invoices saved before payments were tracked');
      expect(rows['a']!['paid_amount'], 0, reason: 'unpaid invoices keep no payment');
      final lines = await old.query('line_items');
      expect(lines.map((l) => l['id']), ['kept']);

      // Foreign keys can now be enforced without errors.
      await old.execute('PRAGMA foreign_keys = ON');
      final violations = await old.rawQuery('PRAGMA foreign_key_check');
      expect(violations, isEmpty);
    });
  });
}
