import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/ads/ad_manager.dart';
import '../../core/theme/app_colors.dart';

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.slate700,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Icon & PRO Badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // High Impact Headline
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Make Invoicing\nEven easier',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Feature Checklist with Teal Checkmarks
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildFeatureItem(
                              'Unlimited GST & Pro Invoices',
                              'Create and send invoices with zero monthly limits.',
                            ),
                            _buildFeatureItem(
                              'Custom Branding & Logo',
                              'Export clean PDF invoices with no watermark.',
                            ),
                            _buildFeatureItem(
                              'Client & Inventory Manager',
                              'Save unlimited clients and product details.',
                            ),
                            _buildFeatureItem(
                              'Premium Support 24/7',
                              'Direct priority support from our developer team.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Pricing & CTA Area (Grouped Inset Container)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Side-by-Side Pricing Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildPricingBox(
                          title: 'Monthly',
                          price:
                              _getProduct(AdManager.monthlyProductId)?.price ??
                              '₹299',
                          period: '/ month',
                          badge: 'POPULAR',
                          badgeColor: AppColors.primary,
                          isSelected:
                              _selectedProductId == AdManager.monthlyProductId,
                          onTap: () => setState(
                            () => _selectedProductId =
                                AdManager.monthlyProductId,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPricingBox(
                          title: 'Lifetime',
                          price:
                              _getProduct(AdManager.productId)?.price ??
                              '₹2,999',
                          period: 'one-time',
                          badge: 'BEST PRICE',
                          badgeColor: AppColors.primary,
                          isSelected:
                              _selectedProductId == AdManager.productId,
                          onTap: () => setState(
                            () => _selectedProductId = AdManager.productId,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Full-Width Stadium Pill CTA
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.ctaGradient,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 77, 64, 0.30),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _available && !_isLoading ? _buyProduct : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
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
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer Restore & Privacy links
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
                          '•',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBox({
    required String title,
    required String price,
    required String period,
    required String badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              const BoxShadow(
                color: Color.fromRGBO(0, 191, 165, 0.15),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accentCyan : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentCyan
                          : AppColors.slate300,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              period,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.slate100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.slate600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// NEW Hero animation — an invoice document that writes itself:
// header fills in, then line items stamp across one by one,
// a gold ✓ seal pulses at the end, then loops.
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceProAnimation extends StatefulWidget {
  final double size;
  const _InvoiceProAnimation({required this.size});

  @override
  State<_InvoiceProAnimation> createState() => _InvoiceProAnimationState();
}

class _InvoiceProAnimationState extends State<_InvoiceProAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Phase timings (0–1 normalised)
  // 0.00 – 0.20  paper slides up
  // 0.20 – 0.40  header block draws in
  // 0.40 – 0.75  3 line-item rows stamp in sequentially
  // 0.75 – 0.90  total row highlights
  // 0.90 – 1.00  gold seal pops + holds
  static const _paperStart = 0.0;
  static const _paperEnd = 0.20;
  static const _headerStart = 0.20;
  static const _headerEnd = 0.40;
  static const _row1Start = 0.40;
  static const _row1End = 0.55;
  static const _row2Start = 0.52;
  static const _row2End = 0.67;
  static const _row3Start = 0.64;
  static const _row3End = 0.78;
  static const _totalStart = 0.75;
  static const _totalEnd = 0.90;
  static const _sealStart = 0.88;
  static const _sealEnd = 1.00;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _runLoop();
  }

  void _runLoop() async {
    while (mounted) {
      try {
        await _ctrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 1600));
        if (!mounted) break;
        await _ctrl.reverse();
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _phase(double start, double end) =>
      ((_ctrl.value - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final paperProgress = _phase(_paperStart, _paperEnd);
        final headerProgress = _phase(_headerStart, _headerEnd);
        final row1Progress = _phase(_row1Start, _row1End);
        final row2Progress = _phase(_row2Start, _row2End);
        final row3Progress = _phase(_row3Start, _row3End);
        final totalProgress = _phase(_totalStart, _totalEnd);
        final sealProgress = _phase(_sealStart, _sealEnd);

        // Paper slides up with a slight elastic overshoot
        final paperOffset =
            (1.0 - Curves.easeOutBack.transform(paperProgress)) * 18.0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow behind the doc
            Opacity(
              opacity: paperProgress * 0.6,
              child: Container(
                width: size * 0.9,
                height: size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // The document card
            Transform.translate(
              offset: Offset(0, paperOffset),
              child: Opacity(
                opacity: paperProgress.clamp(0.0, 1.0),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2035),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(size * 0.10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header block ──────────────────────────────────
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: headerProgress,
                          child: Row(
                            children: [
                              Container(
                                width: size * 0.14,
                                height: size * 0.14,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: size * 0.08,
                                ),
                              ),
                              SizedBox(width: size * 0.05),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: size * 0.38,
                                    height: size * 0.045,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  SizedBox(height: size * 0.02),
                                  Container(
                                    width: size * 0.24,
                                    height: size * 0.03,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: size * 0.07),

                      // Thin divider
                      Opacity(
                        opacity: headerProgress,
                        child: Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),

                      SizedBox(height: size * 0.07),

                      // ── Line items ────────────────────────────────────
                      _buildRow(
                        size,
                        row1Progress,
                        const Color(0xFF60A5FA),
                        0.55,
                      ),
                      SizedBox(height: size * 0.045),
                      _buildRow(
                        size,
                        row2Progress,
                        const Color(0xFF34D399),
                        0.45,
                      ),
                      SizedBox(height: size * 0.045),
                      _buildRow(
                        size,
                        row3Progress,
                        const Color(0xFFA78BFA),
                        0.50,
                      ),

                      SizedBox(height: size * 0.07),

                      // ── Total row ─────────────────────────────────────
                      Opacity(
                        opacity: totalProgress,
                        child: Container(
                          height: size * 0.085,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.15 + totalProgress * 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: totalProgress * 0.5),
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size * 0.05,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: size * 0.22,
                                height: size * 0.035,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                width: size * 0.22,
                                height: size * 0.04,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Gold seal ─────────────────────────────────────────────
            if (sealProgress > 0)
              Positioned(
                top: -10,
                right: -6,
                child: Transform.scale(
                  scale: Curves.elasticOut
                      .transform(sealProgress)
                      .clamp(0.0, 1.4),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow(
    double size,
    double progress,
    Color dotColor,
    double barFraction,
  ) {
    return ClipRect(
      child: Align(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: size * 0.05,
              height: size * 0.05,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: size * 0.04),
            Expanded(
              child: Container(
                height: size * 0.032,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(width: size * 0.04),
            Container(
              width: size * barFraction * 0.4,
              height: size * 0.032,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
