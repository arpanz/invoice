import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  system,
  en,
  hi;

  Locale? get locale => this == system ? null : Locale(name);
}

class LocaleController extends ChangeNotifier {
  static const prefKey = 'app_locale';

  AppLanguage _language = AppLanguage.system;
  AppLanguage get language => _language;
  Locale? get locale => _language.locale;

  static Future<AppLanguage> readLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(prefKey)) {
      'en' => AppLanguage.en,
      'hi' => AppLanguage.hi,
      _ => AppLanguage.system,
    };
  }

  Future<void> load() async => _language = await readLanguage();

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, language.name);
    notifyListeners();
  }
}
