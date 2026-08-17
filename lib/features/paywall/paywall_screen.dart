import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/ads/ad_manager.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/paywall_skyline_header.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = true;
  bool _isLoading = false;
  String _selectedProductId = AdManager.productId;

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _restoreTimer;
  bool _purchaseHandled = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initStore();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoreTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initStore() async {
    final bool isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      if (mounted) setState(() => _available = false);
      return;
    }
    if (AdManager.instance.products.isNotEmpty) {
      if (mounted) {
        setState(() => _products = AdManager.instance.products);
      }
    }
    _subscription = _iap.purchaseStream.listen(
      (data) => _listenToPurchaseUpdated(data),
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Store Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    if (_products.isEmpty) {
      final ProductDetailsResponse response = await _iap.queryProductDetails({
        AdManager.productId,
        AdManager.yearlyProductId,
        AdManager.monthlyProductId,
      });
      if (mounted) {
        setState(() {
          _products = response.productDetails;
          AdManager.instance.products = _products;
        });
      }
    }
  }

  ProductDetails? _getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> list) async {
    for (final purchase in list) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isLoading = true);
      } else {
        if (purchase.status == PurchaseStatus.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Purchase Failed: ${purchase.error?.message ?? 'Unknown error'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final knownIds = {
            AdManager.productId,
            AdManager.yearlyProductId,
            AdManager.monthlyProductId,
            AdManager.legacyProductId,
          };
          if (knownIds.contains(purchase.productID)) {
            _restoreTimer?.cancel();
            if (!_purchaseHandled) {
              _purchaseHandled = true;
              await _grantPremium();
            }
          } else {
            if (mounted) setState(() => _isLoading = false);
          }
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _grantPremium() async {
    try {
      await AdManager.instance.enableProVersion();
    } catch (e) {
      debugPrint('Paywall: enableProVersion error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Invoice Maker Pro Activated! All Pro features unlocked.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _buyProduct() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found. Please try again later.'),
        ),
      );
      return;
    }
    final selectedId = _selectedProductId;
    final product = _getProduct(selectedId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected product not available. Please try again.'),
        ),
      );
      return;
    }
    _purchaseHandled = false;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (mounted) setState(() => _isLoading = true);
    _restoreTimer?.cancel();
    _purchaseHandled = false;
    try {
      await _iap.restorePurchases();
      _restoreTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous purchases found for this account.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      _restoreTimer?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── Scrollable content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    PaywallSkylineHeader(
                      onClose: () => Navigator.pop(context),
                    ),
                    _buildFeaturesList(),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA area ──────────────────────────────────────
            _buildBottomCta(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ── Features list ────────────────────────────────────────────────────────

  Widget _buildFeaturesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'WHAT\'S INCLUDED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.slate400,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 18),

          _buildFeatureRow(
            Icons.receipt_long_rounded,
            'Unlimited Invoices',
            'Create and send GST invoices with no limits.',
          ),
          _buildFeatureRow(
            Icons.branding_watermark_rounded,
            'Custom Branding & Logo',
            'Clean PDF exports, no watermark.',
          ),
          _buildFeatureRow(
            Icons.palette_rounded,
            '10 Premium PDF Themes',
            'Modern, Minimalist, Corporate & more.',
          ),
          _buildFeatureRow(
            Icons.people_alt_rounded,
            'Client & Inventory Manager',
            'Save clients, items & quick search.',
          ),
          _buildFeatureRow(
            Icons.support_agent_rounded,
            'Priority Support',
            'Fast-track help & automatic backups.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCta(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding > 0 ? bottomPadding : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pricing cards
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  label: 'Monthly',
                  price:
                      _getProduct(AdManager.monthlyProductId)?.price ?? '₹299',
                  period: '/month',
                  isSelected:
                      _selectedProductId == AdManager.monthlyProductId,
                  onTap: () => setState(
                    () => _selectedProductId = AdManager.monthlyProductId,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlanCard(
                  label: 'Lifetime',
                  price:
                      _getProduct(AdManager.productId)?.price ?? '₹2,999',
                  period: 'one-time',
                  badge: 'BEST VALUE',
                  isSelected: _selectedProductId == AdManager.productId,
                  onTap: () => setState(
                    () => _selectedProductId = AdManager.productId,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _available && !_isLoading ? _buyProduct : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.slate300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _selectedProductId == AdManager.productId
                          ? 'Unlock Lifetime Access'
                          : 'Subscribe for ${_getProduct(_selectedProductId)?.price ?? 'Pro'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _restorePurchases,
                child: const Text(
                  'Restore purchase',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '·',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String label,
    required String price,
    required String period,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + radio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.slate300,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              period,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Badge
            if (badge != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.proGold.withValues(alpha: 0.12)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.proGold : AppColors.slate500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
