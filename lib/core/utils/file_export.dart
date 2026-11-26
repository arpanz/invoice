import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';

/// Where a saved file went, and how to open it.
class SavedFile {
  /// Content URI (Android Downloads) or file path (iOS Documents).
  final String location;

  /// Where to tell the user it is, e.g. "Downloads".
  final String placeLabel;

  const SavedFile(this.location, this.placeLabel);
}

/// Saves documents where the user can find them.
///
/// - Android 10+: the public Downloads folder (MediaStore, no permission).
/// - iOS: the app's Documents folder, shown in the Files app under
///   "On My iPhone".
/// - Otherwise (older Android, or a failure): returns null, and the caller
///   offers the system share sheet so the user can pick where to save.
class FileExport {
  FileExport._();

  static const _channel = MethodChannel('com.livinlabs.invoice/downloads');

  /// A safe file name for a document number, e.g. "Invoice_INV00012.pdf".
  static String pdfName(String kind, String number) =>
      '${kind}_${number.replaceAll(RegExp(r'[^\w-]'), '_')}.pdf';

  static Future<SavedFile?> savePdf(Uint8List bytes, String fileName, {AppLocalizations? localizations}) async {
    final l10n = localizations ?? AppLocalizationsEn();
    try {
      if (Platform.isAndroid) {
        final uri = await _channel.invokeMethod<String>('saveToDownloads', {
          'bytes': bytes,
          'fileName': fileName,
          'mimeType': 'application/pdf',
        });
        return uri == null ? null : SavedFile(uri, l10n.downloads);
      }
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return SavedFile(file.path, l10n.filesOnMyIphoneInvoiceMakerPro);
      }
    } catch (e) {
      debugPrint('Save to device failed: $e');
    }
    return null;
  }

  /// Opens a file saved by [savePdf]. Returns false if no app could open it.
  static Future<bool> open(SavedFile file) async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod<bool>('openUri', {
              'uri': file.location,
              'mimeType': 'application/pdf',
            }) ??
            false;
      }
      // iOS has no "open with" without a plugin: the share sheet offers
      // Quick Look, Files and other apps.
      await SharePlus.instance.share(ShareParams(files: [XFile(file.location)]));
      return true;
    } catch (e) {
      debugPrint('Open saved file failed: $e');
      return false;
    }
  }

  /// Fallback: lets the user pick where to save through the share sheet.
  static Future<void> saveViaShareSheet(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], fileNameOverrides: [fileName]),
    );
  }
}
