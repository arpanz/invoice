import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Holds the user's System / Light / Dark choice and applies it.
///
/// [AppColors] tokens are plain getters that read [AppColors.isDark], so
/// changing the theme means setting that flag and rebuilding every widget.
/// Load it before `runApp` so the first frame already has the right colours.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const prefKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => AppColors.isDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = switch (prefs.getString(prefKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _apply(rebuild: false);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, mode.name);
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode != ThemeMode.system) return;
    if (_apply()) notifyListeners();
  }

  bool _resolveDark() => switch (_mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  /// Sets [AppColors.isDark]; returns true if it changed.
  bool _apply({bool rebuild = true}) {
    final dark = _resolveDark();
    if (dark == AppColors.isDark) return false;
    AppColors.isDark = dark;
    if (rebuild) _rebuildAll();
    return true;
  }

  /// Widgets read colours in their build methods, so every element has to
  /// build again, including routes and sheets already on screen.
  static void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }

  /// Status bar and navigation bar icons that suit the current theme.
  static SystemUiOverlayStyle get overlayStyle {
    final dark = AppColors.isDark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.canvas,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
