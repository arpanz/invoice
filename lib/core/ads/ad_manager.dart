import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();

  // ── Pro state ──────────────────────────────────────────────────────────────
  bool _isPro = false;
  bool get isPro => _isPro;

  // ── IAP Product IDs ────────────────────────────────────────────────────────
  static const String productId = 'invoice_pro_lifetime';
  static const String yearlyProductId = 'invoice_pro_yearly';
  static const String monthlyProductId = 'invoice_pro_monthly';
  static const String legacyProductId = 'invoice_maker_pro_lifetime';
  static const String appStoreUrl =
      'https://play.google.com/store/apps/details?id=com.livinlabs.invoice';
  List<ProductDetails> products = [];

  /// Returns a ready-to-use [Widget]. Returns [SizedBox.shrink] as ads are removed.
  Widget getNativeAdWidget({double height = 120}) {
    return const SizedBox.shrink();
  }

  // ── Paywall trigger hook ───────────────────────────────────────────────────
  static Future<void> Function(BuildContext context)? onShowPaywall;

  // ── Initialization ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_premium_user') ?? false;

    if (_isPro) {
      _validatePremiumState();
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
                  p.productID == monthlyProductId ||
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
    debugPrint('AdManager: Premium disabled.');
  }

  Future<void> enableProVersion() async {
    _isPro = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', true);
    debugPrint('AdManager: Premium enabled!');
  }

  void showInterstitial(BuildContext context, {VoidCallback? onAdDismissed}) {
    onAdDismissed?.call();
  }

  void refreshNativeAd() {}

  // ── Banner ─────────────────────────────────────────────────────────────────
  Widget getBannerAdWidget() {
    return const SizedBox.shrink();
  }
}
