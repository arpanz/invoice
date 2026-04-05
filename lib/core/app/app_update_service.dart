import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdateAvailability {
  available,
  upToDate,
  unsupported,
  unavailable,
  failed,
}

enum AppUpdateStartResult {
  started,
  cancelled,
  unavailable,
  unsupported,
  failed,
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({required this.status, this.info, this.error});

  final AppUpdateAvailability status;
  final AppUpdateInfo? info;
  final Object? error;
}

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  AppUpdateInfo? _lastKnownUpdateInfo;

  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const AppUpdateCheckResult(
        status: AppUpdateAvailability.unsupported,
      );
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      _lastKnownUpdateInfo = info;

      if (_isUpdateAvailable(info)) {
        return AppUpdateCheckResult(
          status: AppUpdateAvailability.available,
          info: info,
        );
      }

      return AppUpdateCheckResult(
        status: AppUpdateAvailability.upToDate,
        info: info,
      );
    } catch (error) {
      return AppUpdateCheckResult(
        status: AppUpdateAvailability.failed,
        error: error,
      );
    }
  }

  Future<AppUpdateStartResult> startUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AppUpdateStartResult.unsupported;
    }

    final info = _lastKnownUpdateInfo ?? (await checkForUpdate()).info;
    if (info == null || !_isUpdateAvailable(info)) {
      return AppUpdateStartResult.unavailable;
    }

    try {
      final AppUpdateResult result;

      if (info.immediateUpdateAllowed) {
        result = await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        return AppUpdateStartResult.unavailable;
      }

      switch (result) {
        case AppUpdateResult.success:
          return AppUpdateStartResult.started;
        case AppUpdateResult.userDeniedUpdate:
          return AppUpdateStartResult.cancelled;
        case AppUpdateResult.inAppUpdateFailed:
          return AppUpdateStartResult.failed;
      }
    } catch (_) {
      return AppUpdateStartResult.failed;
    }
  }

  bool _isUpdateAvailable(AppUpdateInfo info) {
    return info.updateAvailability == UpdateAvailability.updateAvailable ||
        info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress;
  }
}
