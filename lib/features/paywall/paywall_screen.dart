import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/ads/ad_manager.dart';

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
  late Animation<double> _scaleAnimation;
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
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
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
    const accentColor = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1120),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF151829), Color(0xFF0D0F1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 26,
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
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                                height: 1.15,
                              ),
                              children: [
                                TextSpan(text: 'Unlock\nInvoice Maker '),
                                TextSpan(
                                  text: 'Pro',
                                  style: TextStyle(color: Color(0xFFFFD700)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Create unlimited invoices, save more clients, access full history, and remove PDF watermarks.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white54,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildFeatureRow(
                                Icons.all_inclusive_rounded,
                                'Unlimited Invoices',
                                'Create and send more than 10 invoices per calendar month.',
                                Colors.blueAccent,
                              ),
                              _buildFeatureRow(
                                Icons.people_outline_rounded,
                                'Unlimited Clients',
                                'Save and manage more than 5 clients in your workspace.',
                                const Color(0xFF10B981),
                              ),
                              _buildFeatureRow(
                                Icons.history_rounded,
                                'Full Invoice History',
                                'Access all your past invoices (free is limited to the last 5).',
                                Colors.orangeAccent,
                              ),
                              _buildFeatureRow(
                                Icons.star_rounded,
                                'Remove PDF Watermark',
                                'Export clean PDF invoices with no app branding.',
                                const Color(0xFFFFD700),
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
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B2E),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPricingBox(
                            title: 'Monthly',
                            price:
                                _getProduct(
                                  AdManager.monthlyProductId,
                                )?.price ??
                                '...',
                            subtitle: 'Cancel anytime',
                            badge: null,
                            badgeColor: Colors.white30,
                            isSelected:
                                _selectedProductId ==
                                AdManager.monthlyProductId,
                            onTap: () => setState(
                              () => _selectedProductId =
                                  AdManager.monthlyProductId,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPricingBox(
                            title: 'Yearly',
                            price:
                                _getProduct(AdManager.yearlyProductId)?.price ??
                                '...',
                            subtitle: 'Save big',
                            badge: 'BEST VALUE',
                            badgeColor: accentColor,
                            isSelected:
                                _selectedProductId == AdManager.yearlyProductId,
                            onTap: () => setState(
                              () => _selectedProductId =
                                  AdManager.yearlyProductId,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPricingBox(
                            title: 'Lifetime',
                            price:
                                _getProduct(AdManager.productId)?.price ??
                                '...',
                            subtitle: 'Own forever',
                            badge: 'POPULAR',
                            badgeColor: const Color(0xFFEF4444),
                            isSelected:
                                _selectedProductId == AdManager.productId,
                            onTap: () => setState(
                              () => _selectedProductId = AdManager.productId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _available && !_isLoading
                              ? _buyProduct
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _selectedProductId == AdManager.productId
                                      ? 'Get Lifetime Access'
                                      : _selectedProductId ==
                                            AdManager.yearlyProductId
                                      ? 'Start Yearly Plan'
                                      : 'Start Monthly Plan',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTrustBadge(
                            _selectedProductId == AdManager.productId
                                ? '✓  Lifetime'
                                : _selectedProductId ==
                                      AdManager.yearlyProductId
                                ? '✓  Yearly'
                                : '✓  Monthly',
                          ),
                          _dot(),
                          _buildTrustBadge(
                            _selectedProductId == AdManager.productId
                                ? '✓  No subscription'
                                : '✓  Cancel anytime',
                          ),
                          _dot(),
                          _buildTrustBadge('✓  GST-ready'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _restorePurchases,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white38,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Already purchased? Restore Purchases',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text('•', style: TextStyle(color: Colors.white24, fontSize: 11)),
  );

  Widget _buildTrustBadge(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _buildPricingBox({
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const accentColor = Color(0xFFFFD700);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.08)
                : const Color(0xFF222540),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: isSelected ? accentColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white54 : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: -24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 7.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4ADE80),
            size: 18,
          ),
        ],
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
