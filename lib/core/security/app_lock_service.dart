import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_en.dart';

enum AppLockTimeout {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const AppLockTimeout(this.delay);
  final Duration delay;

  String label(AppLocalizations l10n) => delay == Duration.zero
      ? l10n.immediately
      : l10n.minutesCount(delay.inMinutes);
}

bool shouldLockAfterBackground(Duration elapsed, AppLockTimeout timeout) =>
    timeout == AppLockTimeout.immediately || elapsed > timeout.delay;

class AppLockService extends ChangeNotifier {
  AppLockService._(this._prefs, this._authentication)
    : _enabled = _prefs.getBool(_enabledKey) ?? false,
      _locked = _prefs.getBool(_enabledKey) ?? false,
      _timeout = AppLockTimeout.values.firstWhere(
        (value) => value.delay.inSeconds == _prefs.getInt(_timeoutKey),
        orElse: () => AppLockTimeout.oneMinute,
      );

  static const _enabledKey = 'app_lock_enabled';
  static const _timeoutKey = 'app_lock_timeout_seconds';

  final SharedPreferences _prefs;
  final LocalAuthentication _authentication;

  bool _enabled;
  bool _locked;
  bool _foreground = true;
  bool _busy = false;
  AppLockTimeout _timeout;
  Stopwatch? _backgroundTime;

  bool get enabled => _enabled;
  bool get covered => _enabled && (_locked || !_foreground);
  bool get locked => _locked;
  bool get busy => _busy;
  AppLockTimeout get timeout => _timeout;

  static Future<AppLockService> load({
    @visibleForTesting LocalAuthentication? authentication,
  }) async => AppLockService._(
    await SharedPreferences.getInstance(),
    authentication ?? LocalAuthentication(),
  );

  void updateLifecycle(AppLifecycleState state) {
    final previous = covered;
    final wasLocked = _locked;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      final elapsed = _backgroundTime?.elapsed;
      _backgroundTime = null;
      if (_enabled &&
          elapsed != null &&
          shouldLockAfterBackground(elapsed, _timeout)) {
        _locked = true;
      }
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundTime ??= Stopwatch()..start();
    }
    if (previous != covered || wasLocked != _locked) notifyListeners();
  }

  Future<String?> setEnabled(bool value, {AppLocalizations? localizations}) => _run(localizations, (l10n) async {
    if (_enabled == value) return null;
    if (value) {
      final error = await _authenticate(
        l10n, l10n.authenticateToEnableAppLock,
      );
      if (error != null) return error;
    }
    if (!await _prefs.setBool(_enabledKey, value)) {
      return l10n.cannotSaveAppLock;
    }
    _enabled = value;
    _locked = false;
    _backgroundTime = null;
    return null;
  });

  Future<String?> setTimeout(AppLockTimeout value, {AppLocalizations? localizations}) => _run(localizations, (l10n) async {
    if (!await _prefs.setInt(_timeoutKey, value.delay.inSeconds)) {
      return l10n.cannotSaveLockTimeout;
    }
    _timeout = value;
    return null;
  });

  Future<String?> unlock({AppLocalizations? localizations}) => _run(localizations, (l10n) async {
    if (!_locked || !_foreground) return null;
    final error = await _authenticate(l10n, l10n.unlockApp);
    if (error == null) {
      _locked = false;
      // Always clear: the credential screen can be a separate activity, so
      // this may run before the app reports `resumed` again, and a leftover
      // stopwatch would re-lock right after a successful unlock.
      _backgroundTime = null;
    }
    return error;
  });

  Future<String?> _run(AppLocalizations? localizations, Future<String?> Function(AppLocalizations) action) async {
    final l10n = localizations ?? AppLocalizationsEn();
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      return await action(l10n);
    } catch (error) {
      debugPrint('App lock operation failed: $error');
      return l10n.appLockOperationFailed;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> _authenticate(AppLocalizations l10n, String reason) async {
    try {
      if (!await _authentication.isDeviceSupported()) {
        return l10n.ensureScreenLock;
      }
      final authenticated = await _authentication.authenticate(
        localizedReason: reason,
      );
      return authenticated ? null : l10n.authenticationIncomplete;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled => l10n.ensureScreenLock,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          l10n.authenticationTemporarilyLocked,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => l10n.authenticationIncomplete,
        _ => l10n.authenticationUnavailable,
      };
    } on UnsupportedError {
      return l10n.ensureScreenLock;
    }
  }
}
