import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/estimates/models/estimate_model.dart';
import '../../features/invoices/models/document_numbering.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/invoices/models/line_item_model.dart';
import '../../features/invoices/models/payment_model.dart';
import 'package:uuid/uuid.dart';
import '../../features/clients/models/client_model.dart';
import '../utils/image_store.dart';

/// Thrown when a document number is already used by another document.
class DuplicateNumberException implements Exception {
  final String number;
  const DuplicateNumberException(this.number);
  @override
  String toString() => 'Number $number is already used by another document.';
}

/// Thrown when an estimate has already been converted to an invoice.
class AlreadyConvertedException implements Exception {
  const AlreadyConvertedException();
  @override
  String toString() => 'This estimate has already been converted to an invoice.';
}

class DbProvider {
  DbProvider._();

  static Database? _database;

  static const String _dbName = 'invoice_maker_pro.db';
  static const int _dbVersion = 8;

  // Table names
  static const String tableClients = 'clients';
  static const String tableInvoices = 'invoices';
  static const String tableLineItems = 'line_items';
  static const String tableEstimates = 'estimates';
  static const String tableEstimateLineItems = 'estimate_line_items';
  static const String tableSavedItems = 'saved_items';
  static const String tablePayments = 'payments';

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableClients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        gstin TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableInvoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        client_id TEXT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        client_gstin TEXT,
        invoice_date INTEGER NOT NULL,
        due_date INTEGER,
        subtotal REAL NOT NULL DEFAULT 0,
        discount_type TEXT DEFAULT 'none',
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        sgst_rate REAL DEFAULT 0,
        cgst_rate REAL DEFAULT 0,
        igst_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        shipping REAL DEFAULT 0,
        grand_total REAL NOT NULL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'unpaid',
        notes TEXT,
        custom_fields TEXT,
        currency TEXT DEFAULT 'INR',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        issuer_snapshot TEXT,
        sent_at INTEGER,
        attachments TEXT,
        FOREIGN KEY (client_id) REFERENCES $tableClients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLineItems (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        discount_rate REAL DEFAULT 0,
        tax_rate REAL,
        hsn_sac TEXT,
        unit TEXT,
        FOREIGN KEY (invoice_id) REFERENCES $tableInvoices(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableEstimates (
        id TEXT PRIMARY KEY,
        estimate_number TEXT NOT NULL UNIQUE,
        client_id TEXT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        client_gstin TEXT,
        estimate_date INTEGER NOT NULL,
        expiry_date INTEGER,
        subtotal REAL NOT NULL DEFAULT 0,
        discount_type TEXT DEFAULT 'none',
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        sgst_rate REAL DEFAULT 0,
        cgst_rate REAL DEFAULT 0,
        igst_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        grand_total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        converted_invoice_id TEXT,
        notes TEXT,
        custom_fields TEXT,
        currency TEXT DEFAULT 'INR',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (client_id) REFERENCES $tableClients(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableEstimateLineItems (
        id TEXT PRIMARY KEY,
        estimate_id TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        discount_rate REAL DEFAULT 0,
        tax_rate REAL,
        hsn_sac TEXT,
        unit TEXT,
        FOREIGN KEY (estimate_id) REFERENCES $tableEstimates(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSavedItems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        unit_price REAL NOT NULL DEFAULT 0,
        unit TEXT DEFAULT 'pcs',
        hsn_code TEXT,
        category TEXT,
        is_taxable INTEGER DEFAULT 1,
        tax_rate REAL DEFAULT 0,
        discount_rate REAL DEFAULT 0,
        default_quantity REAL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_invoices_client ON $tableInvoices(client_id)');
    await db.execute('CREATE INDEX idx_invoices_status ON $tableInvoices(status)');
    await db.execute('CREATE INDEX idx_line_items_invoice ON $tableLineItems(invoice_id)');
    await db.execute('CREATE INDEX idx_estimates_client ON $tableEstimates(client_id)');
    await db.execute('CREATE INDEX idx_estimates_status ON $tableEstimates(status)');
    await db.execute('CREATE INDEX idx_estimate_line_items_estimate ON $tableEstimateLineItems(estimate_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_items_category ON $tableSavedItems(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_items_name ON $tableSavedItems(name)');
    await _createPaymentsTable(db);
  }

  static Future<void> _createPaymentsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePayments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_on INTEGER NOT NULL,
        method TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES $tableInvoices(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_invoice ON $tablePayments(invoice_id)');
  }

  /// v6: payment history. Each invoice that already shows money received
  /// gets one payment for that amount, so the paid figure stays the same.
  static Future<void> _upgradeToV6(Database db) async {
    await _createPaymentsTable(db);
    // Fixed ids ('pay-<invoice id>'), so running this again adds nothing.
    await db.execute('''
      INSERT OR IGNORE INTO $tablePayments (id, invoice_id, amount, paid_on, note, created_at)
      SELECT 'pay-' || id, id, ROUND(paid_amount, 2), updated_at,
             'Recorded before payment history', updated_at
      FROM $tableInvoices
      WHERE COALESCE(paid_amount, 0) > 0.005
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableEstimates (
          id TEXT PRIMARY KEY,
          estimate_number TEXT NOT NULL UNIQUE,
          client_id TEXT,
          client_name TEXT NOT NULL,
          client_email TEXT,
          client_phone TEXT,
          client_address TEXT,
          client_gstin TEXT,
          estimate_date INTEGER NOT NULL,
          expiry_date INTEGER,
          subtotal REAL NOT NULL DEFAULT 0,
          discount_type TEXT DEFAULT 'none',
          discount_value REAL DEFAULT 0,
          discount_amount REAL DEFAULT 0,
          sgst_rate REAL DEFAULT 0,
          cgst_rate REAL DEFAULT 0,
          igst_rate REAL DEFAULT 0,
          tax_amount REAL DEFAULT 0,
          grand_total REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'pending',
          converted_invoice_id TEXT,
          notes TEXT,
          currency TEXT DEFAULT 'INR',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (client_id) REFERENCES $tableClients(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableEstimateLineItems (
          id TEXT PRIMARY KEY,
          estimate_id TEXT NOT NULL,
          description TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 1,
          unit_price REAL NOT NULL DEFAULT 0,
          total REAL NOT NULL DEFAULT 0,
          sort_order INTEGER DEFAULT 0,
          FOREIGN KEY (estimate_id) REFERENCES $tableEstimates(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_estimates_client ON $tableEstimates(client_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_estimates_status ON $tableEstimates(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_estimate_line_items_estimate ON $tableEstimateLineItems(estimate_id)');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableInvoices ADD COLUMN paid_amount REAL DEFAULT 0');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSavedItems (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          unit_price REAL NOT NULL DEFAULT 0,
          unit TEXT DEFAULT 'pcs',
          hsn_code TEXT,
          category TEXT,
          is_taxable INTEGER DEFAULT 1,
          tax_rate REAL DEFAULT 0,
          discount_rate REAL DEFAULT 0,
          default_quantity REAL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      try {
        await db.execute('ALTER TABLE $tableSavedItems ADD COLUMN tax_rate REAL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableSavedItems ADD COLUMN discount_rate REAL DEFAULT 0');
      } catch (_) {}
      await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_items_category ON $tableSavedItems(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_saved_items_name ON $tableSavedItems(name)');
    }

    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }

    if (oldVersion < 6) {
      await _upgradeToV6(db);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      await _addColumnIfMissing(db, tableInvoices, 'attachments', 'TEXT');
    }
    if (oldVersion < 8 && newVersion >= 8) {
      for (final table in [tableInvoices, tableEstimates]) {
        await _addColumnIfMissing(db, table, 'custom_fields', 'TEXT');
      }
    }
  }

  static Future<void> _onConfigure(Database db) async {
    // Enforce foreign keys (ON DELETE CASCADE for line items). Rows that
    // would violate them are repaired by the v5 upgrade before this matters.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// v5: shipping, issuer snapshot and per-line discount/tax columns, plus a
  /// one-time repair of data written while foreign keys were off. Every step
  /// is idempotent so a failed upgrade can safely run again.
  static Future<void> _upgradeToV5(Database db) async {
    await _addColumnIfMissing(db, tableInvoices, 'shipping', 'REAL DEFAULT 0');
    await _addColumnIfMissing(db, tableInvoices, 'issuer_snapshot', 'TEXT');
    await _addColumnIfMissing(db, tableInvoices, 'sent_at', 'INTEGER');
    for (final table in [tableLineItems, tableEstimateLineItems]) {
      await _addColumnIfMissing(db, table, 'discount_rate', 'REAL DEFAULT 0');
      await _addColumnIfMissing(db, table, 'tax_rate', 'REAL');
      await _addColumnIfMissing(db, table, 'hsn_sac', 'TEXT');
      await _addColumnIfMissing(db, table, 'unit', 'TEXT');
    }

    // Shipping used to be folded into grand_total with no column of its own.
    // Recover it as whatever the total holds beyond taxable value plus tax.
    // The taxable value is clamped at 0 (a flat discount larger than the
    // subtotal was stored unclamped), so this never invents shipping.
    await db.execute('''
      UPDATE $tableInvoices
      SET shipping = ROUND(grand_total - (MAX(subtotal - discount_amount, 0) + tax_amount), 2)
      WHERE COALESCE(shipping, 0) = 0
        AND grand_total - (MAX(subtotal - discount_amount, 0) + tax_amount) > 0.009
    ''');

    // The v3 upgrade back-filled paid_amount with 0, so invoices marked Paid
    // before it show nothing paid. A Paid invoice was paid in full.
    await db.execute('''
      UPDATE $tableInvoices SET paid_amount = grand_total
      WHERE status = 'paid' AND COALESCE(paid_amount, 0) = 0
    ''');

    // Orphans left behind because ON DELETE CASCADE never ran.
    await db.execute(
      'DELETE FROM $tableLineItems WHERE invoice_id NOT IN (SELECT id FROM $tableInvoices)',
    );
    await db.execute(
      'DELETE FROM $tableEstimateLineItems WHERE estimate_id NOT IN (SELECT id FROM $tableEstimates)',
    );
    // Documents pointing at deleted clients keep their client snapshot but
    // lose the dangling reference.
    for (final table in [tableInvoices, tableEstimates]) {
      await db.execute(
        'UPDATE $table SET client_id = NULL '
        'WHERE client_id IS NOT NULL AND client_id NOT IN (SELECT id FROM $tableClients)',
      );
    }
  }

  static Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ─── Generic CRUD helpers ───────────────────────────────────────────────────

  /// Inserts a new row. Fails (never silently replaces) if the id or a
  /// unique column already exists. Use [update] or the document methods below
  /// to change existing rows.
  static Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.abort);
    return data['id'] as String;
  }

  static Future<int> update(
    String table,
    Map<String, dynamic> data,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(table, data, where: whereClause, whereArgs: whereArgs);
  }

  static Future<int> delete(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  static Future<void> execute(String sql, [List<Object?>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  static Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  static Future<int> countInvoicesThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableInvoices WHERE created_at >= ?',
      [startOfMonth],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> countEstimatesThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableEstimates WHERE created_at >= ?',
      [startOfMonth],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Numbering ─────────────────────────────────────────────────────────────

  static Future<String> getNextEstimateNumber({DocumentNumbering? numbering}) async =>
      _nextDocumentNumber(await database, estimate: true, numbering: numbering);

  static Future<String> getNextInvoiceNumber({DocumentNumbering? numbering}) async =>
      _nextDocumentNumber(await database, estimate: false, numbering: numbering);

  static Future<String> _nextDocumentNumber(
    DatabaseExecutor db, {
    required bool estimate,
    DocumentNumbering? numbering,
    DateTime? date,
  }) async {
    final settings = numbering ??
        DocumentNumbering.read(await SharedPreferences.getInstance());
    return nextNumber(
      db,
      estimate ? tableEstimates : tableInvoices,
      estimate ? 'estimate_number' : 'invoice_number',
      settings.prefix(estimate: estimate, date: date ?? DateTime.now()),
      digits: settings.digits,
      startAt: estimate ? settings.nextEstimate : settings.nextInvoice,
    );
  }

  /// Advances past the highest number in the exact prefix and width series.
  /// The start value is a floor. Check every candidate for exact collisions,
  /// including when the counter grows beyond the configured padding.
  @visibleForTesting
  static Future<String> nextNumber(
    DatabaseExecutor db,
    String table,
    String column,
    String prefix, {
    int digits = 5,
    int startAt = 1,
  }) async {
    final rows = await db.rawQuery(
      'SELECT $column AS n FROM $table WHERE instr($column, ?) = 1',
      [prefix],
    );
    final series = RegExp('^${RegExp.escape(prefix)}([0-9]{$digits})' r'$');
    var maxN = 0;
    final existing = <String>{};
    for (final row in rows) {
      final n = row['n'] as String;
      existing.add(n);
      final m = series.firstMatch(n);
      if (m != null) {
        final v = int.parse(m.group(1)!);
        if (v > maxN) maxN = v;
      }
    }
    var next = BigInt.from(startAt > maxN ? startAt : maxN + 1);
    String format() => '$prefix${next.toString().padLeft(digits, '0')}';
    while (existing.contains(format())) {
      next += BigInt.one;
    }
    return format();
  }

  static bool _isUniqueViolation(Object e) =>
      e is DatabaseException && e.isUniqueConstraintError();

  // ─── Documents (transactional) ─────────────────────────────────────────────

  /// Creates or updates an invoice and replaces its lines, atomically.
  /// Throws [DuplicateNumberException] if another invoice has the number.
  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final db = await database;
    try {
      final removedAttachments = await db.transaction((txn) async {
        final previous = await _invoiceAttachments(txn, invoice.id);
        await _saveInvoiceTxn(txn, invoice);
        return previous.toSet().difference(invoice.attachments.toSet());
      });
      await _deleteUnusedAttachments(db, removedAttachments);
    } catch (e) {
      if (_isUniqueViolation(e)) throw DuplicateNumberException(invoice.invoiceNumber);
      rethrow;
    }
  }

  static Future<void> _saveInvoiceTxn(Transaction txn, InvoiceModel invoice) async {
    final row = invoice.toMap();
    // On an existing invoice the paid amount and status come from its
    // payments, never from the editor, so a stale editor can't undo a
    // payment recorded elsewhere.
    final updateRow = Map<String, dynamic>.of(row)
      ..remove('paid_amount')
      ..remove('status');
    // Never INSERT OR REPLACE an invoice: with foreign keys on, the replace
    // deletes the row and cascades away its payments.
    final updated = await txn.update(tableInvoices, updateRow, where: 'id = ?', whereArgs: [invoice.id]);
    final isNew = updated == 0;
    if (isNew) {
      await txn.insert(tableInvoices, row, conflictAlgorithm: ConflictAlgorithm.abort);
    }
    await txn.delete(tableLineItems, where: 'invoice_id = ?', whereArgs: [invoice.id]);
    for (var i = 0; i < invoice.lineItems.length; i++) {
      final item = invoice.lineItems[i].copyWith(invoiceId: invoice.id, sortOrder: i);
      await txn.insert(tableLineItems, item.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    }
    // A new invoice may start with money already received.
    if (isNew && invoice.paidAmount > 0.005) {
      final now = DateTime.now();
      await txn.insert(tablePayments, PaymentModel(
        id: const Uuid().v4(),
        invoiceId: invoice.id,
        amount: double.parse(invoice.paidAmount.toStringAsFixed(2)),
        paidOn: DateTime(now.year, now.month, now.day),
        createdAt: now,
      ).toMap());
    }
    // The total may have changed, so the status is worked out again.
    await _syncPaidAmount(txn, invoice.id);
  }

  // ─── Payments ──────────────────────────────────────────────────────────────

  /// Payments for one invoice, oldest first.
  static Future<List<PaymentModel>> paymentsFor(String invoiceId) async {
    final db = await database;
    final rows = await db.query(tablePayments,
        where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'paid_on ASC, created_at ASC');
    return rows.map(PaymentModel.fromMap).toList();
  }

  /// Records a payment and updates the invoice's paid amount and status.
  static Future<void> addPayment(PaymentModel payment) async {
    if (payment.amount <= 0) throw ArgumentError.value(payment.amount, 'amount', 'must be more than 0');
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(tablePayments, payment.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      await _syncPaidAmount(txn, payment.invoiceId);
    });
  }

  /// Removes a payment and updates the invoice's paid amount and status.
  static Future<void> deletePayment(String paymentId) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(tablePayments,
          columns: ['invoice_id'], where: 'id = ?', whereArgs: [paymentId]);
      if (rows.isEmpty) return;
      await txn.delete(tablePayments, where: 'id = ?', whereArgs: [paymentId]);
      await _syncPaidAmount(txn, rows.first['invoice_id'] as String);
    });
  }

  /// "Mark as paid": records one payment for the balance, dated today.
  /// Returns the new payment's id (null if nothing was owed), so the
  /// caller can undo it with [deletePayment].
  static Future<String?> markPaidInFull(String invoiceId, {String? method}) async {
    final db = await database;
    String? paymentId;
    await db.transaction((txn) async {
      final inv = await txn.query(tableInvoices,
          columns: ['grand_total'], where: 'id = ?', whereArgs: [invoiceId]);
      if (inv.isEmpty) return;
      final total = (inv.first['grand_total'] as num?)?.toDouble() ?? 0;
      final balance = double.parse((total - await _paymentsSum(txn, invoiceId)).toStringAsFixed(2));
      if (balance > 0.005) {
        final now = DateTime.now();
        paymentId = const Uuid().v4();
        await txn.insert(tablePayments, PaymentModel(
          id: paymentId!,
          invoiceId: invoiceId,
          amount: balance,
          paidOn: DateTime(now.year, now.month, now.day),
          method: method,
          createdAt: now,
        ).toMap());
      }
      await _syncPaidAmount(txn, invoiceId);
    });
    return paymentId;
  }

  /// "Mark as unpaid": removes every payment recorded for the invoice.
  static Future<void> clearPayments(String invoiceId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tablePayments, where: 'invoice_id = ?', whereArgs: [invoiceId]);
      await _syncPaidAmount(txn, invoiceId);
    });
  }

  static Future<double> _paymentsSum(DatabaseExecutor txn, String invoiceId) async {
    final r = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS s FROM $tablePayments WHERE invoice_id = ?', [invoiceId]);
    return (r.first['s'] as num).toDouble();
  }

  /// paid_amount is a cached sum of the payments; status follows from it.
  static Future<void> _syncPaidAmount(Transaction txn, String invoiceId) async {
    final inv = await txn.query(tableInvoices,
        columns: ['grand_total'], where: 'id = ?', whereArgs: [invoiceId]);
    if (inv.isEmpty) return;
    final paid = double.parse((await _paymentsSum(txn, invoiceId)).toStringAsFixed(2));
    final total = (inv.first['grand_total'] as num?)?.toDouble() ?? 0;
    await txn.update(
      tableInvoices,
      {
        'paid_amount': paid,
        'status': InvoiceModel.paymentStatusFor(paid, total).value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// Creates or updates an estimate and replaces its lines, atomically.
  /// Throws [DuplicateNumberException] if another estimate has the number.
  static Future<void> saveEstimate(EstimateModel estimate) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final row = estimate.toMap();
        // On an existing estimate the editor never owns its status or its
        // link to a converted invoice (those change through their own
        // actions), so a stale editor can't undo a conversion.
        final updateRow = Map<String, dynamic>.of(row)
          ..remove('status')
          ..remove('converted_invoice_id');
        final updated = await txn.update(tableEstimates, updateRow, where: 'id = ?', whereArgs: [estimate.id]);
        if (updated == 0) {
          await txn.insert(tableEstimates, row, conflictAlgorithm: ConflictAlgorithm.abort);
        }
        await txn.delete(tableEstimateLineItems, where: 'estimate_id = ?', whereArgs: [estimate.id]);
        for (var i = 0; i < estimate.lineItems.length; i++) {
          final item = estimate.lineItems[i].copyWith(invoiceId: estimate.id, sortOrder: i);
          await txn.insert(tableEstimateLineItems, item.toEstimateMap(),
              conflictAlgorithm: ConflictAlgorithm.abort);
        }
      });
    } catch (e) {
      if (_isUniqueViolation(e)) throw DuplicateNumberException(estimate.estimateNumber);
      rethrow;
    }
  }

  /// Converts [estimate] into a new invoice built by [buildInvoice] (given the
  /// allocated invoice number), in one transaction. Lines get fresh ids, so
  /// the invoice never shares rows with anything else. Fails with
  /// [AlreadyConvertedException] if the estimate is already converted.
  static Future<InvoiceModel> convertEstimate(
    EstimateModel estimate,
    InvoiceModel Function(String invoiceNumber) buildInvoice, {
    required String Function() newId,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final current = await txn.query(tableEstimates,
          columns: ['status', 'converted_invoice_id'], where: 'id = ?', whereArgs: [estimate.id]);
      if (current.isNotEmpty &&
          (current.first['converted_invoice_id'] != null ||
              current.first['status'] == EstimateStatus.converted.value)) {
        throw const AlreadyConvertedException();
      }
      final number = await _nextDocumentNumber(txn, estimate: false);
      final draft = buildInvoice(number);
      final invoice = draft.copyWith(
        invoiceNumber: number,
        customFields: estimate.customFields,
        lineItems: [
          for (final l in draft.lineItems) l.copyWith(id: newId(), invoiceId: draft.id),
        ],
      );
      await _saveInvoiceTxn(txn, invoice);
      await txn.update(
        tableEstimates,
        {
          'status': EstimateStatus.converted.value,
          'converted_invoice_id': invoice.id,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [estimate.id],
      );
      return invoice;
    });
  }

  /// Every invoice with its lines, newest first, in two queries (not one
  /// query per invoice).
  static Future<List<InvoiceModel>> loadInvoices() async {
    final db = await database;
    final rows = await db.query(tableInvoices, orderBy: 'invoice_date DESC, invoice_number DESC');
    final lineRows = await db.query(tableLineItems, orderBy: 'sort_order ASC');
    final byInvoice = <String, List<LineItemModel>>{};
    for (final r in lineRows) {
      final line = LineItemModel.fromMap(r);
      byInvoice.putIfAbsent(line.invoiceId, () => []).add(line);
    }
    return [
      for (final r in rows) InvoiceModel.fromMap(r, items: byInvoice[r['id']] ?? const []),
    ];
  }

  /// Copies [source] as a new unpaid draft dated today, with the next number
  /// in the series and fresh line ids.
  static Future<InvoiceModel> duplicateInvoice(
    InvoiceModel source, {
    required String newInvoiceId,
    required String Function() newLineId,
    DateTime? now,
  }) async {
    final db = await database;
    final today = now ?? DateTime.now();
    return db.transaction((txn) async {
      final number = await _nextDocumentNumber(txn, estimate: false, date: today);
      final termDays = source.dueDate?.difference(source.invoiceDate).inDays;
      final attachments = await _invoiceAttachments(
        txn,
        source.id,
        fallback: source.attachments,
      );
      final invoice = source.copyWith(
        attachments: attachments,
        id: newInvoiceId,
        invoiceNumber: number,
        invoiceDate: today,
        dueDate: termDays != null ? today.add(Duration(days: termDays)) : null,
        clearDueDate: termDays == null,
        paidAmount: 0,
        status: InvoiceStatus.unpaid,
        createdAt: today,
        updatedAt: today,
        lineItems: [
          for (final l in source.lineItems) l.copyWith(id: newLineId(), invoiceId: newInvoiceId),
        ],
      );
      await _saveInvoiceTxn(txn, invoice);
      return invoice;
    });
  }

  /// Deletes an invoice, its lines and payments, and any unshared photos.
  static Future<void> deleteInvoice(String id) async {
    final db = await database;
    final attachments = await db.transaction((txn) async {
      final paths = await _invoiceAttachments(txn, id);
      await txn.delete(tableLineItems, where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete(tablePayments, where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete(tableInvoices, where: 'id = ?', whereArgs: [id]);
      // An estimate converted into this invoice goes back to accepted, so it
      // can be converted again.
      await txn.update(
          tableEstimates,
          {
            'converted_invoice_id': null,
            'status': EstimateStatus.accepted.value,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'converted_invoice_id = ?',
          whereArgs: [id]);
      return paths;
    });
    await _deleteUnusedAttachments(db, attachments.toSet());
  }

  static Future<List<String>> _invoiceAttachments(
    DatabaseExecutor db,
    String id, {
    List<String> fallback = const [],
  }) async {
    final rows = await db.query(
      tableInvoices,
      columns: ['attachments'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty
        ? fallback
        : InvoiceModel.decodeAttachmentPaths(rows.single['attachments']);
  }

  static Future<void> _deleteUnusedAttachments(Database db, Set<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await db.transaction((txn) async {
        final rows = await txn.query(
          tableInvoices,
          columns: ['attachments'],
          where: "attachments IS NOT NULL AND attachments != '[]'",
        );
        for (final row in rows) {
          paths.removeAll(InvoiceModel.decodeAttachmentPaths(row['attachments']));
        }
        for (final path in paths) {
          await ImageStore.deleteAttachment(path);
        }
      });
    } catch (e) {
      debugPrint('Invoice attachments not removed: $e');
    }
  }

  /// Deletes an estimate and its lines.
  static Future<void> deleteEstimate(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableEstimateLineItems, where: 'estimate_id = ?', whereArgs: [id]);
      await txn.delete(tableEstimates, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Creates or updates a client.
  static Future<void> saveClient(ClientModel client) async {
    final db = await database;
    await db.transaction((txn) async {
      final row = client.toMap();
      final updated = await txn.update(tableClients, row, where: 'id = ?', whereArgs: [client.id]);
      if (updated == 0) {
        await txn.insert(tableClients, row, conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }

  /// Deletes a client. Invoices and estimates keep their copy of the client's
  /// details; only the link to the deleted record is cleared.
  static Future<void> deleteClient(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [tableInvoices, tableEstimates]) {
        await txn.update(table, {'client_id': null}, where: 'client_id = ?', whereArgs: [id]);
      }
      await txn.delete(tableClients, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// For tests: use an already-open database (e.g. sqflite_common_ffi).
  @visibleForTesting
  static void useDatabaseForTesting(Database db) => _database = db;

  @visibleForTesting
  static Future<void> createSchemaForTesting(Database db, int version) => _onCreate(db, version);

  @visibleForTesting
  static Future<void> upgradeForTesting(Database db, int from, int to) => _onUpgrade(db, from, to);

  @visibleForTesting
  static Future<void> configureForTesting(Database db) => _onConfigure(db);

  @visibleForTesting
  static const int schemaVersion = _dbVersion;
}
