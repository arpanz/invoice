import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();

  // TODO: Replace with real AdMob IDs before publishing
  static const String _bannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String _bannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716'; // Test ID
  static const String _interstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String _interstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910'; // Test ID

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _bannerAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _bannerAdUnitIdIOS;
    }
    return _bannerAdUnitIdAndroid;
  }

  static String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _interstitialAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _interstitialAdUnitIdIOS;
    }
    return _interstitialAdUnitIdAndroid;
  }

  static InterstitialAd? _interstitialAd;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  static void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  static void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Preload next
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
