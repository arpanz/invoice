import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();

  // ── Interstitial state ─────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialRetryAttempt = 0;
  static const int _maxRetryAttempts = 5;

  // ── Native ad state ────────────────────────────────────────────────────────
  NativeAd? _nativeAd;
  bool _isNativeLoaded = false;
  bool _isNativeLoading = false;
  int _nativeRetryAttempt = 0;

  bool get isNativeLoaded => _isNativeLoaded && !_isPro;
  NativeAd? get nativeAd => _isNativeLoaded && !_isPro ? _nativeAd : null;

  // ── Pro state ──────────────────────────────────────────────────────────────
  bool _isPro = false;
  bool get isPro => _isPro;

  // ── IAP Product IDs ────────────────────────────────────────────────────────
  static const String productId = 'invoice_pro_lifetime';
  static const String yearlyProductId = 'invoice_pro_yearly';
  static const String legacyProductId = 'invoice_maker_pro_lifetime';
  static const String appStoreUrl =
      'https://play.google.com/store/apps/details?id=com.livinlabs.invoice';
  List<ProductDetails> products = [];

  // ── Paywall trigger hook ───────────────────────────────────────────────────
  static Future<void> Function(BuildContext context)? onShowPaywall;
  int _interstitialCount = 0;
  int _paywallThreshold = 3;

  // ── Ad Unit IDs ───────────────────────────────────────────────────────────
  // TODO: Replace real banner/interstitial IDs before publishing
  final String _realBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  final String _realInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  final String _realNativeId = 'ca-app-pub-4397005408366648/8428583804';

  // Google test IDs
  final String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  final String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  final String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';

  String get _bannerId => kDebugMode ? _testBannerId : _realBannerId;
  String get _interstitialId =>
      kDebugMode ? _testInterstitialId : _realInterstitialId;
  String get _nativeId => kDebugMode ? _testNativeId : _realNativeId;

  static const List<String> _testDeviceIds = [
    // Add your AdMob test device hash from logcat here
  ];

  // ── Initialization ─────────────────────────────────────────────────────────
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
      _loadNativeAd();
    }
  }

  // ── Premium validation ─────────────────────────────────────────────────────
  Future<void> _validatePremiumState() async {
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return;

      StreamSubscription<List<PurchaseDetails>>? sub;
      sub = iap.purchaseStream.listen((purchases) {
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
      }, onError: (_) => sub?.cancel());

      await iap.restorePurchases();
      Future.delayed(const Duration(seconds: 10), () => sub?.cancel());
    } catch (_) {}
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
    _loadNativeAd();
    debugPrint('AdManager: Premium disabled.');
  }

  Future<void> enableProVersion() async {
    _isPro = true;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', true);
    debugPrint('AdManager: Premium enabled!');
  }

  // ── Interstitial ───────────────────────────────────────────────────────────
  void _loadInterstitial() {
    if (_isPro || _isInterstitialLoading) return;
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

  // ── Native Ad ──────────────────────────────────────────────────────────────
  void _loadNativeAd() {
    if (_isPro || _isNativeLoading) return;
    _isNativeLoading = true;

    _nativeAd?.dispose();
    _nativeAd = NativeAd(
      adUnitId: _nativeId,
      request: const AdRequest(),
      factoryId:
          'listTile', // matches the native factory registered in MainActivity
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdManager: Native ad loaded.');
          _nativeAd = ad as NativeAd;
          _isNativeLoaded = true;
          _isNativeLoading = false;
          _nativeRetryAttempt = 0;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdManager: Native ad failed: ${error.message}');
          ad.dispose();
          _nativeAd = null;
          _isNativeLoaded = false;
          _isNativeLoading = false;
          _retryNativeLoad();
        },
      ),
    );
    _nativeAd!.load();
  }

  void _retryNativeLoad() {
    if (_nativeRetryAttempt >= _maxRetryAttempts) return;
    _nativeRetryAttempt++;
    final delay = Duration(seconds: 1 << _nativeRetryAttempt);
    debugPrint(
      'AdManager: Retrying native in ${delay.inSeconds}s '
      '(attempt $_nativeRetryAttempt/$_maxRetryAttempts)',
    );
    Future.delayed(delay, () => _loadNativeAd());
  }

  /// Refresh the native ad (call after it has been shown for a while)
  void refreshNativeAd() {
    if (_isPro) return;
    _isNativeLoaded = false;
    _nativeRetryAttempt = 0;
    _loadNativeAd();
  }

  // ── Banner ─────────────────────────────────────────────────────────────────
  Widget getBannerAdWidget() {
    if (_isPro) return const SizedBox.shrink();
    return _BannerAdWrapper(adUnitId: _bannerId);
  }

  // ── Native widget helper ───────────────────────────────────────────────────
  /// Returns a ready-to-use [NativeAdWidget]. Returns [SizedBox.shrink] if Pro.
  Widget getNativeAdWidget({double height = 120}) {
    if (_isPro) return const SizedBox.shrink();
    return NativeAdWidget(height: height);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner wrapper (internal)
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// NativeAdWidget — public, drop-in widget
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in native ad widget. Renders nothing for Pro users or before ad loads.
/// Usage:
///   AdManager.instance.getNativeAdWidget()      // via AdManager helper
///   NativeAdWidget(height: 120)                 // direct
class NativeAdWidget extends StatefulWidget {
  final double height;

  const NativeAdWidget({super.key, this.height = 120});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 4;

  // Test native ID — production ID comes from AdManager
  static const String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _realNativeId = 'ca-app-pub-4397005408366648/8428583804';

  String get _adUnitId => kDebugMode ? _testNativeId : _realNativeId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (AdManager.instance.isPro) return;

    _nativeAd?.dispose();
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      // 'listTile' maps to the NativeAdFactory registered in MainActivity.kt
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _isLoaded = true;
              _retryAttempt = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAdWidget: Failed to load: ${error.message}');
          ad.dispose();
          _nativeAd = null;
          _retryLoad();
        },
        onAdClicked: (_) => debugPrint('NativeAdWidget: Ad clicked.'),
        onAdImpression: (_) =>
            debugPrint('NativeAdWidget: Impression recorded.'),
      ),
    );
    _nativeAd!.load();
  }

  void _retryLoad() {
    if (_retryAttempt >= _maxRetries || !mounted) return;
    _retryAttempt++;
    final delay = Duration(seconds: 1 << _retryAttempt);
    debugPrint(
      'NativeAdWidget: Retrying in ${delay.inSeconds}s '
      '(attempt $_retryAttempt/$_maxRetries)',
    );
    Future.delayed(delay, () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdManager.instance.isPro) return const SizedBox.shrink();
    if (!_isLoaded || _nativeAd == null) {
      // Placeholder shimmer while loading
      return Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
