import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoice/core/security/app_lock_gate.dart';
import 'package:invoice/core/security/app_lock_service.dart';
import 'package:invoice/core/theme/app_colors.dart';
import 'package:invoice/core/theme/app_typography.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart' show AuthMessages;
import 'package:shared_preferences/shared_preferences.dart';

/// Succeeds, reporting the app as paused while the credential screen shows.
class _PausingAuth extends LocalAuthentication {
  _PausingAuth(this.onAuthenticate);
  final void Function() onAuthenticate;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    onAuthenticate();
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unlocking while the credential screen pauses the app stays unlocked', () async {
    SharedPreferences.setMockInitialValues({
      'app_lock_enabled': true,
      'app_lock_timeout_seconds': 0,
    });
    late AppLockService lock;
    lock = await AppLockService.load(
      authentication: _PausingAuth(() => lock.updateLifecycle(AppLifecycleState.paused)),
    );
    addTearDown(lock.dispose);
    expect(await lock.unlock(), isNull);
    expect(lock.locked, isFalse);
    lock.updateLifecycle(AppLifecycleState.resumed);
    expect(lock.locked, isFalse);
  });

  test('immediate lock applies to every background trip', () {
    expect(
      shouldLockAfterBackground(Duration.zero, AppLockTimeout.immediately),
      isTrue,
    );
  });

  test('one minute and five minute choices lock only after the timeout', () {
    for (final timeout in [
      AppLockTimeout.oneMinute,
      AppLockTimeout.fiveMinutes,
    ]) {
      expect(shouldLockAfterBackground(Duration.zero, timeout), isFalse);
      expect(shouldLockAfterBackground(timeout.delay, timeout), isFalse);
      expect(
        shouldLockAfterBackground(
          timeout.delay + const Duration(milliseconds: 1),
          timeout,
        ),
        isTrue,
      );
    }
  });

  test('disabled by default with a one-minute timeout', () async {
    SharedPreferences.setMockInitialValues({});
    final lock = await AppLockService.load();
    addTearDown(lock.dispose);
    expect(lock.enabled, isFalse);
    expect(lock.covered, isFalse);
    expect(lock.timeout, AppLockTimeout.oneMinute);
  });

  test('starts covered with the saved policy on cold launch', () async {
    SharedPreferences.setMockInitialValues({
      'app_lock_enabled': true,
      'app_lock_timeout_seconds': 300,
    });
    final lock = await AppLockService.load();
    addTearDown(lock.dispose);
    expect(lock.enabled, isTrue);
    expect(lock.locked, isTrue);
    expect(lock.covered, isTrue);
    expect(lock.timeout, AppLockTimeout.fiveMinutes);
  });

  testWidgets('the lock screen hides invoice content in both themes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
    final lock = await AppLockService.load();
    final previousTheme = AppColors.isDark;
    final previousFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() {
      AppColors.isDark = previousTheme;
      GoogleFonts.config.allowRuntimeFetching = previousFetching;
      lock.dispose();
    });

    for (final isDark in [false, true]) {
      AppColors.isDark = isDark;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTypography.theme,
          builder: (_, child) => AppLockGate(service: lock, child: child!),
          home: const Scaffold(body: Text('Private invoice details')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Private invoice details'), findsNothing);
      expect(
        find.text('Private invoice details', skipOffstage: false),
        findsOneWidget,
      );
    }
  });
}
