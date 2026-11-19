import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Fonts for scripts the bundled fonts don't cover, downloaded only when a
/// document actually contains that script, then kept on the device.
///
/// Arabic, Bengali and Thai ship with the app. The Indic scripts below are
/// fetched from Google Fonts the first time an invoice uses them. Offline
/// with nothing cached, the document still renders; those characters just
/// show as blanks until a later render can download the font.
class PdfScriptFonts {
  PdfScriptFonts._();

  /// Unicode block → font loader. Ranges are inclusive.
  static final List<({int start, int end, String name, Future<pw.Font> Function() load})> _scripts = [
    (start: 0x0900, end: 0x097F, name: 'Devanagari', load: PdfGoogleFonts.notoSansDevanagariRegular),
    (start: 0x0A00, end: 0x0A7F, name: 'Gurmukhi', load: PdfGoogleFonts.notoSansGurmukhiRegular),
    (start: 0x0A80, end: 0x0AFF, name: 'Gujarati', load: PdfGoogleFonts.notoSansGujaratiRegular),
    (start: 0x0B00, end: 0x0B7F, name: 'Oriya', load: PdfGoogleFonts.notoSansOriyaRegular),
    (start: 0x0B80, end: 0x0BFF, name: 'Tamil', load: PdfGoogleFonts.notoSansTamilRegular),
    (start: 0x0C00, end: 0x0C7F, name: 'Telugu', load: PdfGoogleFonts.notoSansTeluguRegular),
    (start: 0x0C80, end: 0x0CFF, name: 'Kannada', load: PdfGoogleFonts.notoSansKannadaRegular),
    (start: 0x0D00, end: 0x0D7F, name: 'Malayalam', load: PdfGoogleFonts.notoSansMalayalamRegular),
    (start: 0x0D80, end: 0x0DFF, name: 'Sinhala', load: PdfGoogleFonts.notoSansSinhalaRegular),
  ];

  static final Map<String, pw.Font> _loaded = {};

  /// Names of the downloadable scripts used in [text], in table order.
  @visibleForTesting
  static List<String> scriptsIn(String text) {
    final found = <String>{};
    for (final rune in text.runes) {
      if (rune < 0x0900 || rune > 0x0DFF) continue;
      for (final s in _scripts) {
        if (rune >= s.start && rune <= s.end) {
          found.add(s.name);
          break;
        }
      }
    }
    return [for (final s in _scripts) if (found.contains(s.name)) s.name];
  }

  /// Fallback fonts for the scripts in [text]. Fonts that cannot be fetched
  /// are skipped, never thrown.
  static Future<List<pw.Font>> fontsFor(String text) async {
    final fonts = <pw.Font>[];
    for (final name in scriptsIn(text)) {
      final cached = _loaded[name];
      if (cached != null) {
        fonts.add(cached);
        continue;
      }
      try {
        final font = await _scripts.firstWhere((s) => s.name == name).load();
        // On a failed download the printing package hands back Helvetica,
        // which has none of these glyphs: don't keep it.
        if (font is pw.TtfFont) {
          _loaded[name] = font;
          fonts.add(font);
        }
      } catch (e) {
        debugPrint('Font for $name not available: $e');
      }
    }
    return fonts;
  }

  /// Keeps downloaded PDF fonts on disk, so each one is fetched once rather
  /// than on every app start. Call once at start-up.
  static Future<void> useDiskCache() async {
    try {
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/pdf_fonts');
      PdfBaseCache.defaultCache = _DiskCache(dir);
    } catch (e) {
      debugPrint('PDF font disk cache unavailable: $e');
    }
  }
}

class _DiskCache extends PdfBaseCache {
  _DiskCache(this.dir);

  final Directory dir;

  File _file(String key) => File('${dir.path}/${key.replaceAll(RegExp(r'[^\w.-]'), '_')}');

  @override
  Future<void> add(String key, Uint8List bytes) async {
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      // Write then rename, so a half-written file is never read as a font.
      final tmp = File('${_file(key).path}.part');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(_file(key).path);
    } catch (e) {
      debugPrint('Could not cache $key: $e');
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    try {
      final f = _file(key);
      return await f.exists() ? await f.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> contains(String key) => _file(key).exists();

  @override
  Future<void> remove(String key) async {
    final f = _file(key);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> clear() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
