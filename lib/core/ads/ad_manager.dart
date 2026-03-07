import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  static final AdManager instance = AdManager._internal();

  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialRetryAttempt = 0;
  static const int _maxRetryAttempts = 5;

  bool _isPro = false;
  bool get isPro => _isPro;

  // IAP Product IDs
  static const String productId = 'invoice_pro_lifetime';
  static const String yearlyProductId = 'invoice_pro_yearly';
  static const String legacyProductId = 'invoice_maker_pro_lifetime';
  static const String appStoreUrl =
      'https://play.google.com/store/apps/details?id=com.arpanz.invoice';
  List<ProductDetails> products = [];

  // HomeScreen will initialize this to show paywall
  static Future<void> Function(BuildContext context)? onShowPaywall;
  int _interstitialCount = 0;
  int _paywallThreshold = 3;

  // TODO: Replace real IDs before publishing
  final String _realBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  final String _realInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  final String _realNativeId = 'ca-app-pub-4397005408366648/8428583804';

  // Test IDs
  final String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  final String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  String get _bannerId => kDebugMode ? _testBannerId : _realBannerId;
  String get _interstitialId =>
      kDebugMode ? _testInterstitialId : _realInterstitialId;

  static const List<String> _testDeviceIds = [
    // Add your AdMob test device hash from logcat here
  ];

  /// Initialize: Load Ads AND Premium Status
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_premium_user') ?? false;

    if (_isPro) {
      _validatePremiumState();
    } else {
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: _testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _loadInterstitial();
    }
  }

  Future<void> _validatePremiumState() async {
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return;

      StreamSubscription<List<PurchaseDetails>>? sub;
      sub = iap.purchaseStream.listen(
        (purchases) {
          final hasPro = purchases.any(
            (p) =>
                (p.productID == productId ||
                    p.productID == yearlyProductId ||
                    p.productID == legacyProductId) &&
                (p.status == PurchaseStatus.purchased ||
                    p.status == PurchaseStatus.restored),
          );
          if (!hasPro) _disableProVersion();
          sub?.cancel();
        },
        onError: (_) => sub?.cancel(),
      );

      await iap.restorePurchases();
      Future.delayed(const Duration(seconds: 10), () => sub?.cancel());
    } catch (e) {
      // Network offline, etc.
    }
  }

  Future<void> _disableProVersion() async {
    _isPro = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', false);
    if (kDebugMode) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }
    await MobileAds.instance.initialize();
    _loadInterstitial();
    debugPrint('AdManager: Premium disabled (subscription expired or missing).');
  }

  /// Call this when a purchase is confirmed
  Future<void> enableProVersion() async {
    _isPro = true;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', true);
    debugPrint('AdManager: Premium enabled!');
  }

  void _loadInterstitial() {
    if (_isPro) return;
    if (_isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdManager: Interstitial failed: ${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _retryInterstitialLoad();
        },
      ),
    );
  }

  void _retryInterstitialLoad() {
    if (_interstitialRetryAttempt >= _maxRetryAttempts) return;
    _interstitialRetryAttempt++;
    final delay = Duration(seconds: 1 << _interstitialRetryAttempt);
    debugPrint(
      'AdManager: Retrying interstitial in ${delay.inSeconds}s '
      '(attempt $_interstitialRetryAttempt/$_maxRetryAttempts)',
    );
    Future.delayed(delay, () => _loadInterstitial());
  }

  void showInterstitial(BuildContext context, {VoidCallback? onAdDismissed}) {
    if (_isPro) {
      onAdDismissed?.call();
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial();

          _interstitialCount++;
          if (_interstitialCount >= _paywallThreshold) {
            _interstitialCount = 0;
            _paywallThreshold++;
            if (context.mounted && onShowPaywall != null) {
              onShowPaywall!(context).then((_) => onAdDismissed?.call());
            } else {
              onAdDismissed?.call();
            }
          } else {
            onAdDismissed?.call();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial();
          onAdDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      _loadInterstitial();
      onAdDismissed?.call();
    }
  }

  Widget getBannerAdWidget() {
    if (_isPro) return const SizedBox.shrink();
    return _BannerAdWrapper(adUnitId: _bannerId);
  }
}

class _BannerAdWrapper extends StatefulWidget {
  final String adUnitId;
  const _BannerAdWrapper({required this.adUnitId});

  @override
  State<_BannerAdWrapper> createState() => _BannerAdWrapperState();
}

class _BannerAdWrapperState extends State<_BannerAdWrapper> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 4;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQueryData.fromView(
        PlatformDispatcher.instance.views.first,
      ).size.width.truncate(),
    );
    if (size == null || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _retryAttempt = 0;
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdManager: Banner failed: ${error.message}');
          ad.dispose();
          _retryLoad();
        },
      ),
    )..load();
  }

  void _retryLoad() {
    if (_retryAttempt >= _maxRetries || !mounted) return;
    _retryAttempt++;
    final delay = Duration(seconds: 1 << _retryAttempt);
    Future.delayed(delay, () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
