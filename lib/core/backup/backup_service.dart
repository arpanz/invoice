import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';

import '../../features/invoices/models/document_custom_field.dart';
import '../../features/invoices/models/document_numbering.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../database/db_provider.dart';
import '../models/currency_model.dart';
import '../providers/currency_provider.dart';
import '../utils/image_store.dart';

enum _BackupFormatIssue { invalid, futureVersion, tooOld, damaged }

/// The file is not a backup this app can restore.
class BackupFormatException implements Exception {
  const BackupFormatException._(this._issue);

  final _BackupFormatIssue _issue;

  String get message => localizedMessage(AppLocalizationsEn());

  String localizedMessage(AppLocalizations l10n) => switch (_issue) {
    _BackupFormatIssue.invalid => l10n.thisFileIsNotAnInvoiceMakerPro,
    _BackupFormatIssue.futureVersion => l10n.backupFromNewerVersion,
    _BackupFormatIssue.tooOld => l10n.backupTooOld,
    _BackupFormatIssue.damaged => l10n.backupDamaged,
  };

  @override
  String toString() => message;
}

/// The records were restored but some settings or images were not.
class BackupIncompleteException implements Exception {
  final Object cause;
  const BackupIncompleteException(this.cause);
  @override
  String toString() => 'Backup restored with errors: $cause';
}

/// An image carried inside a backup.
class BackupImage {
  final Uint8List bytes;

  /// Lower-case extension with the dot, from a fixed list (it ends up in a
  /// file name).
  final String ext;

  /// Where the image lived on the exporting device. Invoice snapshots store
  /// this path, so it is how they are pointed at the restored copy.
  final String? sourcePath;

  const BackupImage(this.bytes, this.ext, this.sourcePath);
}

/// A parsed and fully checked backup, ready to restore.
class BackupContents {
  final int version;
  final DateTime? exportedAt;
  final Map<String, List<Map<String, Object?>>> tables;

  /// Only keys [BackupService.isBackedUpKey] allows: Strings, plus the tax
  /// rate as a double.
  final Map<String, Object> prefs;

  /// 'logo' and/or 'signature'. Always empty for version 3 files.
  final Map<String, BackupImage> images;

  /// Older logos and signatures that saved invoices still point at (each
  /// with its [BackupImage.sourcePath]). Always empty for version 3 files.
  final List<BackupImage> snapshotImages;
  final List<BackupImage> attachmentImages;

  const BackupContents({
    required this.version,
    required this.exportedAt,
    required this.tables,
    required this.prefs,
    required this.images,
    this.snapshotImages = const [],
    this.attachmentImages = const [],
  });

  int count(String table) => tables[table]?.length ?? 0;

  String get summary => localizedSummary(AppLocalizationsEn());

  String localizedSummary(AppLocalizations l10n) => [
    l10n.invoiceCount(count(DbProvider.tableInvoices)),
    l10n.clientCount(count(DbProvider.tableClients)),
    l10n.backupEstimateCount(count(DbProvider.tableEstimates)),
    l10n.savedItemCount(count(DbProvider.tableSavedItems)),
    l10n.backupPaymentCount(count(DbProvider.tablePayments)),
    if (attachmentImages.isNotEmpty)
      l10n.backupAttachmentCount(attachmentImages.length),
  ].join(', ');
}

/// Builds the JSON export and restores it.
///
/// Every method takes the database, preferences and folders as optional
/// arguments so tests can run without platform plugins.
class BackupService {
  BackupService._();

  static const String appName = 'Invoice Maker Pro';
  static const int formatVersion = 4;

  /// A backup with images is a few MB at most; anything far larger is not one.
  // Backups now carry invoice photos, so allow large files.
  static const int maxFileBytes = 400 * 1024 * 1024;

  /// Parents before children, so inserts never break a foreign key. Deletes
  /// run in reverse.
  static const List<String> tablesInInsertOrder = [
    DbProvider.tableClients,
    DbProvider.tableSavedItems,
    DbProvider.tableInvoices,
    DbProvider.tableEstimates,
    DbProvider.tableLineItems,
    DbProvider.tableEstimateLineItems,
    DbProvider.tablePayments,
  ];

  static const String logoKey = 'biz_logo_path';
  static const String signatureKey = 'biz_signature_path';
  static const Map<String, String> _imagePathKeys = {
    'logo': logoKey,
    'signature': signatureKey,
  };
  static const Set<String> _imageExts = {'.png', '.jpg', '.jpeg', '.webp'};

  static const String _currencyKey = 'user_currency';
  static const String _taxRateKey = 'custom_default_tax_rate';

  /// Per-document designs. They belong to the rows, so they travel with them.
  static const List<String> _documentDesignPrefixes = [
    'invoice_customization_',
    'invoice_theme_',
    'estimate_customization_',
    'estimate_theme_',
  ];

  // ─── Which preferences a backup carries ─────────────────────────────────

  /// Business profile and document defaults (all a version 3 file had).
  /// Image paths are device-specific and never travel.
  static bool _isProfileKey(String key) =>
      (key.startsWith('biz_') || key.startsWith('default_')) &&
      key != logoKey &&
      key != signatureKey;

  /// App settings added in version 4: currency, tax rate, document designs.
  static bool _isSettingsKey(String key) =>
      key == _currencyKey ||
      key == _taxRateKey ||
      key == DocumentNumbering.preferencesKey ||
      key == DocumentFieldPreferences.defaultsKey ||
      _documentDesignPrefixes.any(key.startsWith);

  /// True for keys a backup may carry. Everything else (Pro status,
  /// onboarding, theme, review and update prompts, one-time flags) belongs to
  /// this install and is never exported or restored.
  static bool isBackedUpKey(String key) => _isProfileKey(key) || _isSettingsKey(key);

  /// Keys that a backup of [version] speaks for: a restore removes these when
  /// the backup lacks them. A version 3 file knew nothing about currency or
  /// designs, so those are left alone.
  static bool _isCoveredBy(int version, String key) =>
      version >= 4 ? isBackedUpKey(key) : _isProfileKey(key);

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Everything a restore needs, as a JSON-ready map.
  static Future<Map<String, dynamic>> buildExport({
    Database? db,
    SharedPreferences? prefs,
  }) async {
    db ??= await DbProvider.database;
    prefs ??= await SharedPreferences.getInstance();

    final profile = <String, Object?>{};
    final settings = <String, Object?>{};
    for (final key in prefs.getKeys().toList()..sort()) {
      if (_isProfileKey(key)) profile[key] = prefs.get(key);
      if (_isSettingsKey(key)) settings[key] = prefs.get(key);
    }

    final images = <String, Map<String, String>>{};
    for (final entry in _imagePathKeys.entries) {
      final path = prefs.getString(entry.value);
      if (path == null || path.isEmpty) continue;
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        images[entry.key] = {
          'ext': _extOf(path),
          'path': path,
          'data': base64Encode(await file.readAsBytes()),
        };
      } catch (e) {
        // A missing image must not stop the export of the records.
        debugPrint('Backup image skipped: $e');
      }
    }

    // Invoices keep the logo and signature they were made with, which may
    // be older files than the profile's current ones.
    final invoiceRows = await db.query(DbProvider.tableInvoices);
    final profilePaths = {
      for (final image in images.values) image['path']!,
    };
    final snapshotImages = await _exportInvoiceImages(
      invoiceRows.expand((row) => _snapshotPaths(row['issuer_snapshot']))
          .where((path) => !profilePaths.contains(path)),
    );
    final attachmentImages = await _exportInvoiceImages(
      invoiceRows.expand((row) => InvoiceModel.decodeAttachmentPaths(row['attachments'])),
    );

    return {
      'app': appName,
      'version': formatVersion,
      'db_version': await db.getVersion(),
      'exported_at': DateTime.now().toIso8601String(),
      'note': 'Restore this file from Settings > Restore from backup.',
      'business_profile': profile,
      'app_settings': settings,
      'images': images,
      'snapshot_images': snapshotImages,
      'attachment_images': attachmentImages,
      for (final table in tablesInInsertOrder)
        table: table == DbProvider.tableInvoices ? invoiceRows : await db.query(table),
    };
  }

  static Future<List<Map<String, Object>>> _exportInvoiceImages(Iterable<String> paths) async {
    final images = <Map<String, Object>>[];
    for (final path in paths.toSet()) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        images.add({
          'ext': _extOf(path),
          'path': path,
          'data': base64Encode(bytes),
        });
      } catch (e) {
        debugPrint('Backup invoice image skipped: $e');
      }
    }
    return images;
  }

  /// Writes an export to [dir] as `<prefix>_<date>.json`, or as [fileName]
  /// when given.
  static Future<File> writeExport(
    Directory dir, {
    String prefix = 'invoice_maker_pro_export',
    String? fileName,
    Database? db,
    SharedPreferences? prefs,
  }) async {
    final data = await buildExport(db: db, prefs: prefs);
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/${fileName ?? '${prefix}_$dateStr.json'}');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
    return file;
  }

  // ─── Parse and check ────────────────────────────────────────────────────

  /// Parses [text] and checks every part of it. Throws
  /// [BackupFormatException] with a message for the user; touches nothing.
  static BackupContents parse(String text, {required int currentDbVersion}) {
    const notBackup = BackupFormatException._(_BackupFormatIssue.invalid);
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw notBackup;
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != appName) throw notBackup;

    final version = decoded['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException._(_BackupFormatIssue.futureVersion);
    }
    if (version < 3) {
      throw const BackupFormatException._(_BackupFormatIssue.tooOld);
    }

    if (version >= 4) {
      final dbVersion = decoded['db_version'];
      if (dbVersion is! int) throw notBackup;
      if (dbVersion > currentDbVersion) {
        throw const BackupFormatException._(_BackupFormatIssue.futureVersion);
      }
    }

    const damaged = BackupFormatException._(_BackupFormatIssue.damaged);

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in tablesInInsertOrder) {
      final list = decoded[table];
      if (list is! List) throw damaged;
      final rows = <Map<String, Object?>>[];
      for (final row in list) {
        if (row is! Map<String, dynamic>) throw damaged;
        final id = row['id'];
        if (id is! String || id.isEmpty) throw damaged;
        for (final value in row.values) {
          if (value != null && value is! String && value is! num) throw damaged;
        }
        rows.add(Map<String, Object?>.from(row));
      }
      tables[table] = rows;
    }

    final prefs = <String, Object>{};
    for (final section in ['business_profile', if (version >= 4) 'app_settings']) {
      final map = decoded[section];
      if (map == null) continue;
      if (map is! Map<String, dynamic>) throw damaged;
      for (final entry in map.entries) {
        // Unknown or install-only keys (e.g. Pro status) are dropped, not
        // trusted, whatever section they sit in.
        if (!isBackedUpKey(entry.key) || !_isCoveredBy(version, entry.key)) continue;
        final value = entry.value;
        if (value == null) continue;
        if (entry.key == _taxRateKey) {
          if (value is! num) throw damaged;
          prefs[entry.key] = value.toDouble();
        } else if (entry.key == _currencyKey) {
          if (value is! String || !_isCurrencyJson(value)) throw damaged;
          prefs[entry.key] = value;
        } else if (value is String) {
          // Every other key is read with getString; a number or list here
          // would make those reads throw on every launch.
          prefs[entry.key] = value;
        } else {
          throw damaged;
        }
      }
    }

    final images = <String, BackupImage>{};
    // Version 3 files never held images; any image fields in them are ignored.
    if (version >= 4) {
      final map = decoded['images'];
      if (map != null && map is! Map<String, dynamic>) throw damaged;
      for (final kind in _imagePathKeys.keys) {
        final entry = (map as Map<String, dynamic>?)?[kind];
        if (entry == null) continue;
        if (entry is! Map<String, dynamic>) throw damaged;
        final ext = entry['ext'];
        final data = entry['data'];
        final path = entry['path'];
        if (ext is! String || !_imageExts.contains(ext.toLowerCase())) throw damaged;
        if (data is! String) throw damaged;
        if (path != null && path is! String) throw damaged;
        final Uint8List bytes;
        try {
          bytes = base64Decode(data);
        } catch (_) {
          throw damaged;
        }
        if (bytes.isEmpty) throw damaged;
        images[kind] = BackupImage(bytes, ext.toLowerCase(), path as String?);
      }
    }

    List<BackupImage> readInvoiceImages(Object? list) {
      if (list != null && list is! List) throw damaged;
      final images = <BackupImage>[];
      for (final entry in (list as List?) ?? const []) {
        if (entry is! Map<String, dynamic>) throw damaged;
        final ext = entry['ext'];
        final data = entry['data'];
        final path = entry['path'];
        if (ext is! String || !_imageExts.contains(ext.toLowerCase())) throw damaged;
        if (data is! String || path is! String || path.isEmpty) throw damaged;
        final Uint8List bytes;
        try {
          bytes = base64Decode(data);
        } catch (_) {
          throw damaged;
        }
        if (bytes.isEmpty) throw damaged;
        images.add(BackupImage(bytes, ext.toLowerCase(), path));
      }
      return images;
    }

    final exportedAt = decoded['exported_at'];
    return BackupContents(
      version: version,
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      tables: tables,
      prefs: prefs,
      images: images,
      snapshotImages: version >= 4 ? readInvoiceImages(decoded['snapshot_images']) : const [],
      attachmentImages: version >= 4 ? readInvoiceImages(decoded['attachment_images']) : const [],
    );
  }

  /// [parse] against this install's database schema.
  static Future<BackupContents> parseForThisApp(String text, {Database? db}) async {
    db ??= await DbProvider.database;
    return parse(text, currentDbVersion: await db.getVersion());
  }

  static bool _isCurrencyJson(String value) {
    try {
      Currency.fromJson(jsonDecode(value) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Restore ────────────────────────────────────────────────────────────

  /// Replaces all records, the business profile and settings with [backup].
  ///
  /// Order matters so a failure leaves the app as it was:
  /// 1. a safety export of the current data goes to [safetyDir];
  /// 2. images are copied into app storage (removed again on failure);
  /// 3. all tables are replaced in one transaction;
  /// 4. preferences are written.
  /// Steps 1–3 throw with nothing changed. A failure in step 4 throws
  /// [BackupIncompleteException]: the records are already restored.
  ///
  /// Returns the safety export.
  ///
  /// [imagesDir] is where kept images live (ImageStore's folder); the old
  /// logo and signature are deleted from it once the new ones are in.
  static Future<File> restore(
    BackupContents backup, {
    Database? db,
    SharedPreferences? prefs,
    Directory? safetyDir,
    Directory? tempDir,
    Directory? imagesDir,
    Future<String> Function(String path, String kind)? keepImage,
  }) async {
    db ??= await DbProvider.database;
    prefs ??= await SharedPreferences.getInstance();
    keepImage ??= ImageStore.keep;

    final safety = await _writeSafetyExport(db, prefs, safetyDir);
    final oldImagePaths = {
      for (final key in _imagePathKeys.values)
        if (prefs.getString(key) case final path? when path.isNotEmpty) path,
    };
    final oldAttachmentPaths = <String>{};

    // 2. Images first, so invoice snapshots can point at their new paths.
    final newImagePaths = <String, String>{};
    // Invoice-only images: exported path → restored path.
    final snapshotPathMap = <String, String>{};
    final attachmentPathMap = <String, String>{};
    try {
      tempDir ??= await getTemporaryDirectory();
      for (final entry in backup.images.entries) {
        final temp = File(
          '${tempDir.path}/restore_${entry.key}_${DateTime.now().microsecondsSinceEpoch}${entry.value.ext}',
        );
        try {
          await temp.writeAsBytes(entry.value.bytes, flush: true);
          final kept = await keepImage(temp.path, entry.key);
          // ImageStore.keep hands back the source path when the copy fails.
          if (kept == temp.path || !await File(kept).exists()) {
            throw StateError('Could not store the ${entry.key} image');
          }
          newImagePaths[entry.key] = kept;
        } finally {
          await _tryDelete(temp.path);
        }
      }

      for (final (image, kind, paths) in [
        for (final image in backup.snapshotImages) (image, 'invoice', snapshotPathMap),
        for (final image in backup.attachmentImages) (image, 'attachment', attachmentPathMap),
      ]) {
        final temp = File(
          '${tempDir.path}/restore_${kind}_${DateTime.now().microsecondsSinceEpoch}${image.ext}',
        );
        try {
          await temp.writeAsBytes(image.bytes, flush: true);
          final kept = await keepImage(temp.path, kind);
          if (kept == temp.path || !await File(kept).exists()) {
            throw StateError('Could not store an invoice image');
          }
          paths[image.sourcePath!] = kept;
        } finally {
          await _tryDelete(temp.path);
        }
      }

      // 3. One transaction: all or nothing.
      await db.transaction((txn) async {
        final columns = <String, Set<String>>{};
        for (final table in tablesInInsertOrder) {
          final info = await txn.rawQuery('PRAGMA table_info($table)');
          columns[table] = {for (final row in info) row['name'] as String};
        }
        if (columns[DbProvider.tableInvoices]!.contains('attachments')) {
          for (final row in await txn.query(DbProvider.tableInvoices, columns: ['attachments'])) {
            oldAttachmentPaths.addAll(InvoiceModel.decodeAttachmentPaths(row['attachments']));
          }
        }
        for (final table in tablesInInsertOrder.reversed) {
          await txn.delete(table);
        }
        final pathMap = <String, String>{
          for (final entry in backup.images.entries)
            if (entry.value.sourcePath != null && newImagePaths[entry.key] != null)
              entry.value.sourcePath!: newImagePaths[entry.key]!,
          ...snapshotPathMap,
        };
        final batch = txn.batch();
        for (final table in tablesInInsertOrder) {
          final known = columns[table]!;
          for (final row in backup.tables[table]!) {
            final values = <String, Object?>{
              // Columns this schema does not have (from a future or odd
              // file) are dropped rather than failing the insert.
              for (final e in row.entries)
                if (known.contains(e.key)) e.key: e.value,
            };
            if (table == DbProvider.tableInvoices) {
              if (pathMap.isNotEmpty && values.containsKey('issuer_snapshot')) {
                values['issuer_snapshot'] = _remapSnapshot(values['issuer_snapshot'], pathMap);
              }
              if (values['attachments'] != null) {
                values['attachments'] = jsonEncode([
                  for (final path in InvoiceModel.decodeAttachmentPaths(values['attachments']))
                    ?attachmentPathMap[path],
                ]);
              }
            }
            batch.insert(table, values, conflictAlgorithm: ConflictAlgorithm.abort);
          }
        }
        await batch.commit(noResult: true);
      });
    } catch (_) {
      for (final path in [...newImagePaths.values, ...snapshotPathMap.values, ...attachmentPathMap.values]) {
        await _tryDelete(path);
      }
      rethrow;
    }

    // 4. Preferences, after the records are safely in.
    try {
      for (final key in prefs.getKeys().toList()) {
        if (_isCoveredBy(backup.version, key) && !backup.prefs.containsKey(key)) {
          await prefs.remove(key);
        }
      }
      for (final entry in backup.prefs.entries) {
        final value = entry.value;
        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        }
      }
      // A version 3 file has no images, so the current logo and signature
      // stay. From version 4 the backup decides: no image means none.
      if (backup.version >= 4) {
        for (final entry in _imagePathKeys.entries) {
          final path = newImagePaths[entry.key];
          if (path != null) {
            await prefs.setString(entry.value, path);
          } else {
            await prefs.remove(entry.value);
          }
        }
      }
    } catch (e) {
      throw BackupIncompleteException(e);
    }

    if (backup.version >= 4) {
      await _deleteReplacedImages(db, oldImagePaths, newImagePaths.values.toSet(), imagesDir);
    }
    for (final path in oldAttachmentPaths.difference(attachmentPathMap.values.toSet())) {
      await ImageStore.deleteAttachment(path);
    }
    return safety;
  }

  /// The newest copy saved before a restore, so the user can get back to
  /// the data they had. Null when there is none.
  static Future<File?> latestSafetyExport({Directory? dir}) async {
    try {
      dir ??= await _safetyDir();
      if (!await dir.exists()) return null;
      final copies = _safetyExportsIn(dir);
      return copies.isEmpty ? null : copies.first;
    } catch (e) {
      debugPrint('Safety copy lookup failed: $e');
      return null;
    }
  }

  /// Brings [provider] in line with the restored preferences. Its loader is
  /// private, so this goes through the public setters. The currency goes
  /// first because changing it clears any custom tax rate.
  static Future<void> syncCurrencyProvider(
    CurrencyProvider provider, {
    SharedPreferences? prefs,
  }) async {
    prefs ??= await SharedPreferences.getInstance();
    final rate = prefs.getDouble(_taxRateKey);
    final json = prefs.getString(_currencyKey);
    Currency currency = SupportedCurrencies.all.first;
    if (json != null) {
      try {
        currency = Currency.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {}
    }
    await provider.setCurrency(currency);
    if (rate != null) {
      await provider.setCustomTaxRate(rate);
    } else {
      await provider.clearCustomTaxRate();
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  static const String _safetyPrefix = 'invoice_maker_pro_before_restore';

  static Future<Directory> _safetyDir() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/backups');

  /// Safety exports in [dir], newest first. The name carries a sortable
  /// time stamp, which is steadier than file times.
  static List<File> _safetyExportsIn(Directory dir) => dir
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith(_safetyPrefix))
      .toList()
    ..sort((a, b) => b.uri.pathSegments.last.compareTo(a.uri.pathSegments.last));

  /// Keeps the three newest safety exports; each can hold images. The name
  /// is unique to the millisecond so two restores in a row never overwrite
  /// the copy of the original data.
  static Future<File> _writeSafetyExport(
    Database db,
    SharedPreferences prefs,
    Directory? dir,
  ) async {
    dir ??= await _safetyDir();
    final stamp = DateFormat('yyyyMMdd_HHmmss_SSS').format(DateTime.now());
    var name = '${_safetyPrefix}_$stamp.json';
    for (var n = 2; await File('${dir.path}/$name').exists(); n++) {
      name = '${_safetyPrefix}_${stamp}_$n.json';
    }
    final file = await writeExport(dir, fileName: name, db: db, prefs: prefs);
    try {
      final old = _safetyExportsIn(dir).where((f) => f.path != file.path);
      for (final f in old.skip(2)) {
        await _tryDelete(f.path);
      }
    } catch (e) {
      debugPrint('Old safety backups not pruned: $e');
    }
    return file;
  }

  /// Removes the logo and signature files the restore replaced, so each
  /// restore does not leave orphans behind. Only files in the app's images
  /// folder that no restored invoice still points at are removed; the
  /// safety export already holds a copy of them.
  static Future<void> _deleteReplacedImages(
    Database db,
    Set<String> oldPaths,
    Set<String> newPaths,
    Directory? imagesDir,
  ) async {
    try {
      imagesDir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/images');
      final folder = '${imagesDir.path}/';
      for (final path in oldPaths) {
        if (newPaths.contains(path) || !path.startsWith(folder)) continue;
        final used = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM ${DbProvider.tableInvoices} WHERE instr(issuer_snapshot, ?) > 0',
          [path],
        ));
        if ((used ?? 0) == 0) await _tryDelete(path);
      }
    } catch (e) {
      debugPrint('Old profile images not removed: $e');
    }
  }

  /// Points a stored issuer snapshot's logo and signature at the restored
  /// copies when they were the profile images.
  static Object? _remapSnapshot(Object? snapshot, Map<String, String> pathMap) {
    if (snapshot is! String || snapshot.isEmpty) return snapshot;
    try {
      final map = jsonDecode(snapshot);
      if (map is! Map<String, dynamic>) return snapshot;
      var changed = false;
      for (final key in ['logoPath', 'signaturePath']) {
        final mapped = pathMap[map[key]];
        if (mapped != null) {
          map[key] = mapped;
          changed = true;
        }
      }
      return changed ? jsonEncode(map) : snapshot;
    } catch (_) {
      return snapshot;
    }
  }

  /// The logo and signature paths an issuer snapshot points at.
  static Iterable<String> _snapshotPaths(Object? snapshot) sync* {
    if (snapshot is! String || snapshot.isEmpty) return;
    try {
      final map = jsonDecode(snapshot);
      if (map is! Map<String, dynamic>) return;
      for (final key in ['logoPath', 'signaturePath']) {
        final path = map[key];
        if (path is String && path.isNotEmpty) yield path;
      }
    } catch (_) {}
  }

  static String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot > path.lastIndexOf('/') ? path.substring(dot).toLowerCase() : '';
    return _imageExts.contains(ext) ? ext : '.png';
  }

  static Future<void> _tryDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
