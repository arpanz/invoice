import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbProvider {
  DbProvider._();

  static Database? _database;

  static const String _dbName = 'invoice_maker_pro.db';
  static const int _dbVersion = 2;

  // Table names
  static const String tableClients = 'clients';
  static const String tableInvoices = 'invoices';
  static const String tableLineItems = 'line_items';
  static const String tableEstimates = 'estimates';
  static const String tableEstimateLineItems = 'estimate_line_items';

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
        grand_total REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'unpaid',
        notes TEXT,
        currency TEXT DEFAULT 'INR',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
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
        FOREIGN KEY (estimate_id) REFERENCES $tableEstimates(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_invoices_client ON $tableInvoices(client_id)');
    await db.execute('CREATE INDEX idx_invoices_status ON $tableInvoices(status)');
    await db.execute('CREATE INDEX idx_line_items_invoice ON $tableLineItems(invoice_id)');
    await db.execute('CREATE INDEX idx_estimates_client ON $tableEstimates(client_id)');
    await db.execute('CREATE INDEX idx_estimates_status ON $tableEstimates(status)');
    await db.execute('CREATE INDEX idx_estimate_line_items_estimate ON $tableEstimateLineItems(estimate_id)');
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
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ─── Generic CRUD helpers ───────────────────────────────────────────────────

  static Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
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

  static Future<String> getNextEstimateNumber() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableEstimates');
    final count = (Sqflite.firstIntValue(result) ?? 0) + 1;
    return 'EST${count.toString().padLeft(5, '0')}';
  }

  static Future<String> getNextInvoiceNumber() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableInvoices');
    final count = (Sqflite.firstIntValue(result) ?? 0) + 1;
    return 'INV${count.toString().padLeft(5, '0')}';
  }
}
