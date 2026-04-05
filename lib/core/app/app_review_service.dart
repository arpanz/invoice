import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  AppReviewService._();

  static final AppReviewService instance = AppReviewService._();

  static const String _firstSeenKey = 'app_review_first_seen_ms';
  static const String _lastPromptKey = 'app_review_last_prompt_ms';
  static const String _significantActionCountKey =
      'app_review_significant_action_count';
  static const int _minSignificantActionsBeforePrompt = 3;

  static const Duration _minInstallAge = Duration(days: 3);
  static const Duration _promptCooldown = Duration(days: 120);

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> registerLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_firstSeenKey, prefs.getInt(_firstSeenKey) ?? now);
  }

  Future<bool> registerSignificantAction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _significantActionCountKey,
      (prefs.getInt(_significantActionCountKey) ?? 0) + 1,
    );
    return maybeRequestReview();
  }

  Future<bool> maybeRequestReview() async {
    if (kIsWeb || !await _inAppReview.isAvailable()) return false;

    final prefs = await SharedPreferences.getInstance();
    final significantActions = prefs.getInt(_significantActionCountKey) ?? 0;
    final firstSeenMs = prefs.getInt(_firstSeenKey);
    final lastPromptMs = prefs.getInt(_lastPromptKey);
    final now = DateTime.now();

    if (significantActions < _minSignificantActionsBeforePrompt ||
        firstSeenMs == null) {
      return false;
    }

    final firstSeen = DateTime.fromMillisecondsSinceEpoch(firstSeenMs);
    if (now.difference(firstSeen) < _minInstallAge) return false;

    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(lastPrompt) < _promptCooldown) return false;
    }

    try {
      await _inAppReview.requestReview();
      await prefs.setInt(_lastPromptKey, now.millisecondsSinceEpoch);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openRatingFlow() async {
    if (kIsWeb) return false;

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.windows:
          await _inAppReview.openStoreListing();
          return true;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          if (await _inAppReview.isAvailable()) {
            await _inAppReview.requestReview();
            return true;
          }
          return false;
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> openPlayStoreListing() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      await _inAppReview.openStoreListing();
      return true;
    } catch (_) {
      return false;
    }
  }
}
