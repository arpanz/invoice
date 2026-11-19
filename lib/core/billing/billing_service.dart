import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single source of truth for Pro entitlement.
///
/// It listens to the store for the whole app lifetime, acknowledges every
/// purchase (so Google never auto-refunds a pending UPI payment because the
/// paywall was closed), knows every Pro product ID including the legacy one,
/// and is the only object the UI watches for `isPro`.
class BillingService extends ChangeNotifier {
  static const String lifetimeProductId = 'invoice_pro_lifetime';
  static const String yearlyProductId = 'invoice_pro_yearly';
  static const String monthlyProductId = 'invoice_pro_monthly';
  static const String legacyLifetimeProductId = 'invoice_maker_pro_lifetime';

  /// Every product that grants Pro.
  static const Set<String> proProductIds = {
    lifetimeProductId,
    yearlyProductId,
    monthlyProductId,
    legacyLifetimeProductId,
  };

  /// Products offered for sale on the paywall.
  static const Set<String> purchasableProductIds = {
    lifetimeProductId,
    monthlyProductId,
  };

  static const String _prefKeyIsPro = 'is_premium_user';

  BillingService({InAppPurchase? iap}) : _iapOverride = iap;

  final InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPro = false;
  bool _isLoading = false;
  bool _storeAvailable = false;
  bool _awaitingStartupRestore = false;
  String? _errorMessage;
  List<ProductDetails> _products = const [];

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  bool get storeAvailable => _storeAvailable;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  /// Increments every time a purchase or restore grants Pro, so a screen can
  /// react to "Pro was just activated" even if the user was already Pro.
  int _grantCount = 0;
  int get grantCount => _grantCount;

  ProductDetails? productFor(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_prefKeyIsPro) ?? false;
    notifyListeners();

    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('BillingService: store availability check failed: $e');
      _storeAvailable = false;
    }
    if (!_storeAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('BillingService: purchase stream error: $e'),
    );

    // Startup restore re-checks entitlement. If the store answers with no Pro
    // purchase at all, a lapsed subscription is revoked (see _onPurchaseUpdate).
    _awaitingStartupRestore = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _awaitingStartupRestore = false;
      debugPrint('BillingService: startup restore failed: $e');
    }
    unawaited(loadProducts());
  }

  /// Fetches localized prices for the paywall.
  Future<void> loadProducts() async {
    if (!_storeAvailable) return;
    try {
      final response = await _iap.queryProductDetails(purchasableProductIds);
      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      debugPrint('BillingService: product query failed: $e');
    }
  }

  /// Starts a purchase of [productId]. The result arrives on the purchase
  /// stream; watch [isPro], [isLoading] and [errorMessage].
  Future<void> buy(String productId) async {
    _errorMessage = null;
    if (!_storeAvailable) {
      _errorMessage = 'The Play Store is not available right now. Please try again later.';
      notifyListeners();
      return;
    }
    var product = productFor(productId);
    if (product == null) {
      await loadProducts();
      product = productFor(productId);
    }
    if (product == null) {
      _errorMessage = 'This plan is not available right now. Please try again later.';
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('BillingService: buy failed: $e');
      _isLoading = false;
      _errorMessage = 'The purchase could not be started. Please try again.';
      notifyListeners();
    }
  }

  /// User-initiated restore. Returns once the request is sent; the outcome
  /// arrives on the purchase stream.
  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _errorMessage = 'The Play Store is not available right now. Please try again later.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('BillingService: restore failed: $e');
      _errorMessage = 'Could not reach the Play Store to restore purchases.';
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final isStartupRestore = _awaitingStartupRestore;
    _awaitingStartupRestore = false;

    var grantsPro = false;
    for (final purchase in purchases) {
      final isPro = proProductIds.contains(purchase.productID);
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (isPro) grantsPro = true;
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchase.error}');
          _errorMessage = 'The purchase did not go through. You have not been charged. '
              'Please check your connection and Google Play payment method, then try again.';
          _isLoading = false;
          break;
        case PurchaseStatus.canceled:
          _isLoading = false;
          break;
        case PurchaseStatus.pending:
          _isLoading = true;
          break;
      }
      // Always acknowledge, whichever screen is open, or Google refunds the
      // purchase after three days.
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('BillingService: completePurchase failed: $e');
        }
      }
    }

    if (grantsPro) {
      _isLoading = false;
      _grantCount++;
      await _setPro(true);
      return;
    }

    // The store answered the startup restore and reported no Pro purchase at
    // all (an empty list or only unrelated items): the entitlement has lapsed.
    final onlyRestoreResults = purchases.every(
      (p) => p.status == PurchaseStatus.restored,
    );
    if (isStartupRestore && _isPro && onlyRestoreResults) {
      await _setPro(false);
      return;
    }

    notifyListeners();
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsPro, value);
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Test hook: sets Pro without touching the store. Not for app code.
  @visibleForTesting
  Future<void> setProForTesting(bool value) => _setPro(value);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
