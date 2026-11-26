import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/backup/backup_service.dart';
import 'package:invoice/core/database/db_provider.dart';
import 'package:invoice/core/models/currency_model.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _now = 1793404800000; // 2026-11-01

Future<void> seed(Database db) async {
  await db.insert(DbProvider.tableClients, {
    'id': 'c1', 'name': 'Acme', 'email': 'a@acme.test', 'gstin': 'GST1', 'created_at': _now,
  });
  await db.insert(DbProvider.tableSavedItems, {
    'id': 's1', 'name': 'Design', 'unit_price': 50.0, 'tax_rate': 18.0, 'created_at': _now, 'updated_at': _now,
  });
  await db.insert(DbProvider.tableInvoices, {
    'id': 'i1', 'invoice_number': 'INV00001', 'client_id': 'c1', 'client_name': 'Acme',
    'invoice_date': _now, 'subtotal': 100.0, 'grand_total': 118.0, 'paid_amount': 50.0,
    'status': 'partial', 'created_at': _now, 'updated_at': _now,
    'issuer_snapshot': jsonEncode({'businessName': 'Studio', 'logoPath': '/old/logo.png'}),
  });
  await db.insert(DbProvider.tableLineItems, {
    'id': 'l1', 'invoice_id': 'i1', 'description': 'Work', 'quantity': 1.0, 'unit_price': 100.0, 'total': 100.0,
  });
  await db.insert(DbProvider.tableEstimates, {
    'id': 'e1', 'estimate_number': 'EST00001', 'client_id': 'c1', 'client_name': 'Acme',
    'estimate_date': _now, 'created_at': _now, 'updated_at': _now,
  });
  await db.insert(DbProvider.tableEstimateLineItems, {
    'id': 'el1', 'estimate_id': 'e1', 'description': 'Quote', 'quantity': 2.0, 'unit_price': 10.0, 'total': 20.0,
  });
  await db.insert(DbProvider.tablePayments, {
    'id': 'p1', 'invoice_id': 'i1', 'amount': 50.0, 'paid_on': _now, 'method': 'UPI', 'created_at': _now,
  });
}

Future<Map<String, List<Map<String, Object?>>>> dump(Database db) async => {
      for (final t in BackupService.tablesInInsertOrder) t: await db.query(t, orderBy: 'id'),
    };

Future<void> wipe(Database db) async {
  for (final t in BackupService.tablesInInsertOrder.reversed) {
    await db.delete(t);
  }
}

final _india = jsonEncode(SupportedCurrencies.getByCode('INR')!.toJson());
final _usd = jsonEncode(SupportedCurrencies.getByCode('USD')!.toJson());

void main() {
  sqfliteFfiInit();
  late Database db;
  late SharedPreferences prefs;
  late Directory tmp;
  late File logo;

  Future<String> keep(String path, String kind) async {
    final target = '${tmp.path}/kept_${kind}_${DateTime.now().microsecondsSinceEpoch}${path.substring(path.lastIndexOf('.'))}';
    await File(path).copy(target);
    return target;
  }

  Future<File> restore(BackupContents b) => BackupService.restore(
        b,
        db: db,
        prefs: prefs,
        safetyDir: Directory('${tmp.path}/safety'),
        tempDir: tmp,
        imagesDir: tmp,
        keepImage: keep,
      );

  BackupContents parse(Object json) =>
      BackupService.parse(jsonEncode(json), currentDbVersion: DbProvider.schemaVersion);

  Future<Map<String, dynamic>> export() async =>
      jsonDecode(jsonEncode(await BackupService.buildExport(db: db, prefs: prefs))) as Map<String, dynamic>;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbProvider.schemaVersion,
        singleInstance: false,
        onConfigure: DbProvider.configureForTesting,
        onCreate: DbProvider.createSchemaForTesting,
      ),
    );
    tmp = await Directory.systemTemp.createTemp('backup_test');
    logo = File('${tmp.path}/logo.png')..writeAsBytesSync([1, 2, 3, 4]);
    SharedPreferences.setMockInitialValues({
      'biz_name': 'Studio',
      'biz_upi': 'studio@upi',
      'biz_logo_path': logo.path,
      'default_payment_terms': 'Net 15',
      'default_pdf_theme': 'classic',
      'user_currency': _india,
      'custom_default_tax_rate': 12.5,
      'invoice_theme_i1': 'modern',
      'is_premium_user': true,
      'onboarding_complete': true,
      'theme_mode': 'dark',
      'app_review_first_seen_ms': 5,
    });
    prefs = await SharedPreferences.getInstance();
    await seed(db);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('export → wipe → restore gives back every table and setting', () async {
    final before = await dump(db);
    final json = await export();
    expect(json['version'], 4);
    expect(json['db_version'], DbProvider.schemaVersion);
    expect((json['business_profile'] as Map).containsKey('biz_logo_path'), isFalse);
    expect(json.toString(), isNot(contains('is_premium_user')));
    expect(json.toString(), isNot(contains('theme_mode')));
    expect(json['images']['logo']['ext'], '.png');

    final backup = parse(json);
    expect(backup.summary, '1 invoice, 1 client, 1 estimate, 1 saved item, 1 payment');

    await wipe(db);
    for (final key in ['biz_name', 'biz_upi', 'default_payment_terms', 'invoice_theme_i1']) {
      await prefs.remove(key);
    }
    await prefs.setString('biz_bank_name', 'Not in backup');
    await prefs.setString('invoice_theme_gone', 'stale');
    await prefs.setString('user_currency', _usd);
    await prefs.remove('custom_default_tax_rate');

    final safety = await restore(backup);
    expect(safety.existsSync(), isTrue);

    final after = await dump(db);
    for (final t in BackupService.tablesInInsertOrder) {
      if (t == DbProvider.tableInvoices) continue;
      expect(after[t], before[t], reason: t);
    }
    final inv = Map.of(after[DbProvider.tableInvoices]!.single);
    final snap = jsonDecode(inv.remove('issuer_snapshot') as String) as Map;
    final beforeInv = Map.of(before[DbProvider.tableInvoices]!.single)..remove('issuer_snapshot');
    expect(inv, beforeInv);

    expect(prefs.getString('biz_name'), 'Studio');
    expect(prefs.getString('biz_upi'), 'studio@upi');
    expect(prefs.getString('default_payment_terms'), 'Net 15');
    expect(prefs.getString('invoice_theme_i1'), 'modern');
    expect(prefs.getString('user_currency'), _india);
    expect(prefs.getDouble('custom_default_tax_rate'), 12.5);
    expect(prefs.containsKey('biz_bank_name'), isFalse, reason: 'absent from backup');
    expect(prefs.containsKey('invoice_theme_gone'), isFalse, reason: 'stale design key');
    // Install-only keys are untouched.
    expect(prefs.getBool('is_premium_user'), isTrue);
    expect(prefs.getString('theme_mode'), 'dark');

    final newLogo = prefs.getString('biz_logo_path')!;
    expect(newLogo, isNot(logo.path));
    expect(File(newLogo).readAsBytesSync(), [1, 2, 3, 4]);
    expect(prefs.containsKey('biz_signature_path'), isFalse);
    // The snapshot pointed at the exporting device's logo; not remapped
    // here because '/old/logo.png' was not the exported profile logo.
    expect(snap['logoPath'], '/old/logo.png');
  });

  test('custom fields and document defaults survive backup and restore', () async {
    const invoiceFields = '[{"label":"PO Number","value":"PO-42"}]';
    const estimateFields = '[{"label":"Vehicle No.","value":"KA-01"}]';
    const defaults = '[{"label":"PO Number","value":""}]';
    const numbering = '{"invoicePrefix":"INV/26/","digits":3,"nextInvoice":12}';
    await db.update(DbProvider.tableInvoices, {'custom_fields': invoiceFields});
    await db.update(DbProvider.tableEstimates, {'custom_fields': estimateFields});
    await prefs.setString('default_invoice_custom_fields', defaults);
    await prefs.setString('document_numbering', numbering);
    final backup = parse(await export());

    await wipe(db);
    await prefs.remove('default_invoice_custom_fields');
    await prefs.remove('document_numbering');
    await restore(backup);

    expect((await db.query(DbProvider.tableInvoices)).single['custom_fields'], invoiceFields);
    expect((await db.query(DbProvider.tableEstimates)).single['custom_fields'], estimateFields);
    expect(prefs.getString('default_invoice_custom_fields'), defaults);
    expect(prefs.getString('document_numbering'), numbering);
  });

  test('invoice snapshots that used the profile logo point at the restored copy', () async {
    await db.update(DbProvider.tableInvoices, {
      'issuer_snapshot': jsonEncode({'businessName': 'Studio', 'logoPath': logo.path}),
    });
    final backup = parse(await export());
    await restore(backup);
    final row = (await db.query(DbProvider.tableInvoices)).single;
    final snap = jsonDecode(row['issuer_snapshot'] as String) as Map;
    expect(snap['logoPath'], prefs.getString('biz_logo_path'));
    expect(snap['logoPath'], isNot(logo.path));
  });

  test('older logos and signatures that invoices still use travel too', () async {
    final oldSig = File('${tmp.path}/old_signature.png')..writeAsBytesSync([9, 8, 7]);
    await db.update(DbProvider.tableInvoices, {
      'issuer_snapshot': jsonEncode({'businessName': 'Studio', 'signaturePath': oldSig.path, 'logoPath': logo.path}),
    });
    final json = await export();
    // The profile logo is not stored twice; the invoice-only signature is.
    expect((json['snapshot_images'] as List).map((e) => e['path']), [oldSig.path]);

    final backup = parse(json);
    oldSig.deleteSync(); // as if restoring on another phone
    await restore(backup);
    final snap = jsonDecode((await db.query(DbProvider.tableInvoices)).single['issuer_snapshot'] as String) as Map;
    expect(snap['signaturePath'], isNot(oldSig.path));
    expect(File(snap['signaturePath'] as String).readAsBytesSync(), [9, 8, 7]);
    expect(snap['logoPath'], prefs.getString('biz_logo_path'));
  });

  test('backup restores attachment bytes and remaps every invoice reference', () async {
    final photo = File('${tmp.path}/attachment.jpg')..writeAsBytesSync([9, 2, 7]);
    final missing = '${tmp.path}/missing.png';
    await db.update(DbProvider.tableInvoices, {'attachments': jsonEncode([photo.path, missing])});
    final original = (await db.query(DbProvider.tableInvoices)).single;
    await db.insert(DbProvider.tableInvoices, {
      ...original,
      'id': 'i2',
      'invoice_number': 'INV00002',
      'attachments': jsonEncode([photo.path]),
    });

    final backup = parse(await export());
    expect(backup.attachmentImages, hasLength(1));
    expect(backup.summary, endsWith('1 attachment photo'));
    await photo.delete();
    await wipe(db);
    await restore(backup);

    final invoices = await db.query(DbProvider.tableInvoices, orderBy: 'id');
    final firstPaths = jsonDecode(invoices.first['attachments'] as String) as List;
    final restored = firstPaths.single as String;
    expect(restored, isNot(photo.path));
    expect(File(restored).readAsBytesSync(), [9, 2, 7]);
    expect(jsonDecode(invoices.last['attachments'] as String), [restored]);
  });

  test('a damaged invoice image list is rejected', () async {
    final json = await export();
    json['snapshot_images'] = [
      {'ext': '.png', 'data': 'AQID'},
    ];
    expect(() => parse(json), throwsA(isA<BackupFormatException>()));
  });

  test('a version 3 file is accepted and leaves currency and images alone', () async {
    final json = await export();
    final v3 = {
      'app': 'Invoice Maker Pro',
      'version': 3,
      'business_profile': {
        'biz_name': 'Old Name',
        'default_payment_terms': 'Net 30',
        'biz_logo_path': '/somewhere/else.png',
        'biz_signature_path': '/somewhere/sig.png',
        'user_currency': _usd,
      },
      for (final t in BackupService.tablesInInsertOrder) t: json[t],
    };
    final backup = parse(v3);
    expect(backup.images, isEmpty);
    await prefs.setString('biz_email', 'drop@me.test');
    await restore(backup);

    expect(prefs.getString('biz_name'), 'Old Name');
    expect(prefs.getString('default_payment_terms'), 'Net 30');
    expect(prefs.containsKey('biz_email'), isFalse);
    expect(prefs.getString('biz_logo_path'), logo.path, reason: 'v3 path keys ignored');
    expect(prefs.containsKey('biz_signature_path'), isFalse);
    expect(prefs.getString('user_currency'), _india);
    expect(prefs.getDouble('custom_default_tax_rate'), 12.5);
    expect(prefs.getString('invoice_theme_i1'), 'modern');
    expect((await db.query(DbProvider.tableInvoices)).length, 1);
  });

  test('a backup from a newer database is rejected', () async {
    final json = await export()..['db_version'] = DbProvider.schemaVersion + 1;
    expect(() => parse(json), throwsA(isA<BackupFormatException>()));
    final newer = await export()..['version'] = 5;
    expect(() => parse(newer), throwsA(isA<BackupFormatException>()));
  });

  test('malformed files are rejected before anything changes', () async {
    final before = await dump(db);
    final good = await export();
    final bad = <Object>[
      {'app': 'Something else', 'version': 4},
      {...good, 'invoices': 'nope'},
      {...good, 'clients': [1, 2]},
      {...good}..remove('payments'),
      {...good, 'db_version': 'six'},
      {...good, 'line_items': [{'id': 'x', 'description': {'nested': true}}]},
      {...good, 'images': {'logo': {'ext': '.exe', 'data': 'AAAA'}}},
      {...good, 'images': {'logo': {'ext': '.png', 'data': '%%%not base64'}}},
      {...good, 'app_settings': {'custom_default_tax_rate': 'ten'}},
      {...good, 'business_profile': {'biz_name': 5}},
      {...good, 'app_settings': {'user_currency': 'not a currency'}},
    ];
    for (final json in bad) {
      expect(() => parse(json), throwsA(isA<BackupFormatException>()), reason: 'case ${bad.indexOf(json)}');
    }
    expect(
      () => BackupService.parse('{not json', currentDbVersion: DbProvider.schemaVersion),
      throwsA(isA<BackupFormatException>()),
    );
    expect(await dump(db), before);
    expect(prefs.getString('biz_name'), 'Studio');
  });

  test('a file that breaks the schema rolls back and changes nothing', () async {
    final before = await dump(db);
    final good = await export();
    final orphan = {
      ...good,
      'line_items': [
        ...good['line_items'] as List,
        {'id': 'l9', 'invoice_id': 'missing', 'description': 'x', 'quantity': 1, 'unit_price': 1, 'total': 1},
      ],
      'business_profile': {'biz_name': 'Should not land'},
    };
    final duplicate = {
      ...good,
      'invoices': [
        ...good['invoices'] as List,
        {...(good['invoices'] as List).first as Map, 'id': 'i2'},
      ],
    };
    for (final json in [orphan, duplicate]) {
      await expectLater(restore(parse(json)), throwsA(anything));
      expect(await dump(db), before);
      expect(prefs.getString('biz_name'), 'Studio');
      expect(prefs.getString('biz_logo_path'), logo.path);
    }
    // The images written for the failed attempts were cleaned up.
    expect(tmp.listSync().where((f) => f.path.contains('kept_')), isEmpty);
  });

  test('unknown columns are ignored', () async {
    final json = await export();
    (json['clients'] as List).first['loyalty_tier'] = 'gold';
    (json['payments'] as List).first['future_column'] = 42;
    await restore(parse(json));
    final client = (await db.query(DbProvider.tableClients)).single;
    expect(client['name'], 'Acme');
    expect(client.containsKey('loyalty_tier'), isFalse);
    expect((await db.query(DbProvider.tablePayments)).single['amount'], 50.0);
  });

  test('install-only keys like Pro status are never restored', () async {
    await prefs.setBool('is_premium_user', false);
    await prefs.setBool('onboarding_complete', false);
    final json = await export();
    (json['business_profile'] as Map)['is_premium_user'] = true;
    (json['app_settings'] as Map)['is_premium_user'] = true;
    (json['app_settings'] as Map)['onboarding_complete'] = true;
    (json['app_settings'] as Map)['theme_mode'] = 'light';
    final backup = parse(json);
    expect(backup.prefs.containsKey('is_premium_user'), isFalse);
    await restore(backup);
    expect(prefs.getBool('is_premium_user'), isFalse);
    expect(prefs.getBool('onboarding_complete'), isFalse);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('path keys in a file are never written as they are', () async {
    final json = await export();
    (json['business_profile'] as Map)['biz_logo_path'] = '/evil/logo.png';
    (json['business_profile'] as Map)['biz_signature_path'] = '/evil/sig.png';
    (json['app_settings'] as Map)['biz_logo_path'] = '/evil/logo.png';
    await restore(parse(json));
    expect(prefs.getString('biz_logo_path'), isNot('/evil/logo.png'));
    expect(File(prefs.getString('biz_logo_path')!).existsSync(), isTrue);
    expect(prefs.containsKey('biz_signature_path'), isFalse);

    (json['images'] as Map).clear();
    await restore(parse(json));
    expect(prefs.containsKey('biz_logo_path'), isFalse, reason: 'v4 without a logo means none');
  });

  test('a whole-number tax rate is stored as a double', () async {
    final json = await export();
    (json['app_settings'] as Map)['custom_default_tax_rate'] = 18;
    await restore(parse(json));
    expect(prefs.getDouble('custom_default_tax_rate'), 18.0);
  });

  test('the currency provider picks up the restored currency and tax rate', () async {
    final provider = CurrencyProvider();
    while (provider.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.currencyCode, 'INR');
    // As if a restore just wrote a different currency with its own rate.
    await prefs.setString('user_currency', _usd);
    await prefs.setDouble('custom_default_tax_rate', 7.25);
    await BackupService.syncCurrencyProvider(provider, prefs: prefs);
    expect(provider.currencyCode, 'USD');
    expect(provider.customTaxRate, 7.25);
    expect(prefs.getDouble('custom_default_tax_rate'), 7.25);

    await prefs.remove('custom_default_tax_rate');
    await BackupService.syncCurrencyProvider(provider, prefs: prefs);
    expect(provider.hasCustomTaxRate, isFalse);
  });

  test('two restores in a row keep both safety copies', () async {
    final backup = parse(await export());
    final first = await restore(backup);
    final firstText = first.readAsStringSync();
    final second = await restore(backup);
    expect(second.path, isNot(first.path));
    expect(first.readAsStringSync(), firstText, reason: 'the first copy is never overwritten');
    final latest = await BackupService.latestSafetyExport(dir: Directory('${tmp.path}/safety'));
    expect(latest?.path, second.path);
  });

  test('the old logo is removed once replaced, unless an invoice still uses it', () async {
    final backup = parse(await export());
    await restore(backup);
    expect(logo.existsSync(), isFalse, reason: 'replaced and unused');

    final current = prefs.getString('biz_logo_path')!;
    await db.update(DbProvider.tableInvoices, {
      'issuer_snapshot': jsonEncode({'logoPath': current}),
    });
    final again = parse(await export());
    // A restored invoice that names the current logo keeps that file.
    final other = File('${tmp.path}/kept_logo_other.png')..writeAsBytesSync([9]);
    again.tables[DbProvider.tableInvoices]!.single['issuer_snapshot'] =
        jsonEncode({'logoPath': other.path});
    await prefs.setString('biz_logo_path', other.path);
    await restore(again);
    expect(other.existsSync(), isTrue, reason: 'a restored invoice still points at it');
  });

  test('the temp image file is removed when storing the image fails', () async {
    final backup = parse(await export());
    await expectLater(
      BackupService.restore(
        backup,
        db: db,
        prefs: prefs,
        safetyDir: Directory('${tmp.path}/safety'),
        tempDir: tmp,
        imagesDir: tmp,
        keepImage: (path, kind) async => throw StateError('disk full'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(tmp.listSync().where((f) => f.path.contains('restore_')), isEmpty);
    expect(prefs.getString('biz_logo_path'), logo.path, reason: 'nothing changed');
  });
}
