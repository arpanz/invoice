import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps picked images (logo, signature) in the app's own documents folder.
///
/// `image_picker` returns a path in the cache folder, which Android may clear
/// at any time; a logo stored there silently disappears from invoices.
class ImageStore {
  ImageStore._();

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [pickedPath] into app storage and returns the new path. [kind]
  /// names the file, e.g. "logo". Returns [pickedPath] unchanged if it is
  /// already in app storage or the copy fails.
  static Future<String> keep(String pickedPath, String kind) async {
    try {
      final dir = await _dir();
      if (pickedPath.startsWith(dir.path)) return pickedPath;
      final source = File(pickedPath);
      if (!await source.exists()) return pickedPath;
      final dot = pickedPath.lastIndexOf('.');
      final ext = dot > pickedPath.lastIndexOf('/') ? pickedPath.substring(dot) : '.png';
      final target = '${dir.path}/${kind}_${DateTime.now().millisecondsSinceEpoch}$ext';
      await source.copy(target);
      return target;
    } catch (e) {
      debugPrint('Keep image failed: $e');
      return pickedPath;
    }
  }

  /// One-time pass: moves the saved logo and signature out of the cache.
  static Future<void> migrateProfileImages() async {
    const doneKey = 'profile_images_moved_v1_done';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(doneKey) ?? false) return;
    for (final entry in const {'biz_logo_path': 'logo', 'biz_signature_path': 'signature'}.entries) {
      final path = prefs.getString(entry.key);
      if (path == null || path.isEmpty) continue;
      final kept = await keep(path, entry.value);
      if (kept != path) await prefs.setString(entry.key, kept);
    }
    await prefs.setBool(doneKey, true);
  }
}
