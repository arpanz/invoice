import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService extends ChangeNotifier {
  static const String _proProductId = 'invoice_maker_pro_lifetime';
  static const String _prefKeyIsPro = 'is_pro_user';

  bool _isPro = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final InAppPurchase _iap = InAppPurchase.instance;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_prefKeyIsPro) ?? false;
    notifyListeners();

    // Listen to purchase updates
    _iap.purchaseStream.listen(_onPurchaseUpdate);

    // Restore purchases on init
    await restorePurchases();
  }

  Future<void> purchasePro() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _errorMessage = 'Store not available. Please try again later.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _iap.queryProductDetails({_proProductId});
      if (response.productDetails.isEmpty) {
        _errorMessage = 'Product not found. Please try again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = 'Purchase failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _proProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setPro(true);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        } else if (purchase.status == PurchaseStatus.error) {
          _errorMessage = purchase.error?.message ?? 'Purchase error';
          _isLoading = false;
          notifyListeners();
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsPro, value);
    notifyListeners();
  }

  /// For testing/demo purposes only
  Future<void> setProForTesting(bool value) async {
    await _setPro(value);
  }
}
