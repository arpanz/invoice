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

  /// A flexible update finished downloading. It installs when the app
  /// restarts; call [AppUpdateService.completeDownloadedUpdate] once the
  /// user agrees, so unsaved work is never lost to a surprise restart.
  downloaded,
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

      // The prompt offers "Later", so prefer the flexible flow: it downloads
      // in the background while the user keeps working.
      if (info.flexibleUpdateAllowed) {
        result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) return AppUpdateStartResult.downloaded;
      } else if (info.immediateUpdateAllowed) {
        result = await InAppUpdate.performImmediateUpdate();
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

  /// True when a flexible update has downloaded and only needs a restart.
  bool isDownloaded(AppUpdateInfo? info) => info?.installStatus == InstallStatus.downloaded;

  /// Restarts the app to install a downloaded flexible update.
  Future<bool> completeDownloadedUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isUpdateAvailable(AppUpdateInfo info) {
    return info.updateAvailability == UpdateAvailability.updateAvailable ||
        info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress;
  }
}
