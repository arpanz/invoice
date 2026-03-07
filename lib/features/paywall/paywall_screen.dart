import 'dart:async';
import 'dart:io';
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
  bool _isLifetimeSelected = true;

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
    _fadeAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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
    debugPrint('Paywall: IAP Available: $isAvailable');
    if (!isAvailable) {
      if (mounted) setState(() => _available = false);
      return;
    }

    if (AdManager.instance.products.isNotEmpty) {
      debugPrint('Paywall: Using cached products (${AdManager.instance.products.length})');
      if (mounted) setState(() => _products = AdManager.instance.products);
    }

    _subscription = _iap.purchaseStream.listen(
      (data) {
        debugPrint('Paywall: Purchase stream update (${data.length} items)');
        _listenToPurchaseUpdated(data);
      },
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('Paywall: Purchase stream error: $error');
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
      debugPrint('Paywall: Querying product details...');
      final ProductDetailsResponse response = await _iap.queryProductDetails({
        AdManager.productId,
        AdManager.yearlyProductId,
      });
      debugPrint('Paywall: Not found IDs: ${response.notFoundIDs}');
      debugPrint('Paywall: Products found: ${response.productDetails.length}');
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
            AdManager.legacyProductId,
          };
          if (knownIds.contains(purchase.productID)) {
            _restoreTimer?.cancel();
            if (!_purchaseHandled) {
              _purchaseHandled = true;
              await _grantPremium();
            }
          } else {
            debugPrint('Paywall: Ignoring unknown productID: ${purchase.productID}');
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
          content: Text('Invoice Maker Pro Activated! All Pro features unlocked.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _buyProduct() async {
    debugPrint('Paywall: Buy pressed. Products: ${_products.length}');
    try {
      if (_products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found. Please try again later.')),
        );
        return;
      }

      final selectedId =
          _isLifetimeSelected ? AdManager.productId : AdManager.yearlyProductId;
      final product = _getProduct(selectedId);
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected product not available. Please try again.'),
          ),
        );
        return;
      }

      debugPrint('Paywall: Purchasing ${product.id} @ ${product.price}');
      _purchaseHandled = false;
      try {
        await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product),
        );
      } catch (error) {
        debugPrint('Paywall: Purchase initiation error: $error');
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
    } catch (e, stack) {
      debugPrint('Paywall: Exception during buy: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    debugPrint('Paywall: Restore pressed');
    if (mounted) setState(() => _isLoading = true);
    _restoreTimer?.cancel();
    _purchaseHandled = false;

    try {
      await _iap.restorePurchases();
      _restoreTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          debugPrint('Paywall: Restore timeout — no matching purchases found');
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
      debugPrint('Paywall: Restore error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFD700); // Gold — matches csvforge paywall

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
              // ── Close button ─────────────────────────────────────────────
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

              // ── Scrollable feature list ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 4),

                        // Hero animation
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: const _InvoiceProAnimation(size: 120),
                        ),
                        const SizedBox(height: 24),

                        // Headline
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Unlock\nInvoice Maker Pro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.8,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Create unlimited GST-ready invoices, share as PDF, and grow your business — ad-free.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white54,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Feature list
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildFeatureRow(
                                Icons.all_inclusive_rounded,
                                'Unlimited Invoices',
                                'Create & send as many invoices as you need.',
                                Colors.blueAccent,
                              ),
                              _buildFeatureRow(
                                Icons.picture_as_pdf_outlined,
                                'PDF Export & Share',
                                'Professional PDF invoices with your logo & GST.',
                                const Color(0xFFEF4444),
                              ),
                              _buildFeatureRow(
                                Icons.people_outline_rounded,
                                'Unlimited Clients',
                                'Save and manage your entire client list.',
                                const Color(0xFF10B981),
                              ),
                              _buildFeatureRow(
                                Icons.business_center_outlined,
                                'Business Profile',
                                'Add your signature, logo & GSTIN to every invoice.',
                                Colors.purpleAccent,
                              ),
                              _buildFeatureRow(
                                Icons.insights_rounded,
                                'Revenue Dashboard',
                                'Track paid, unpaid & overdue invoices at a glance.',
                                Colors.orangeAccent,
                              ),
                              _buildFeatureRow(
                                Icons.block_flipped,
                                'Ad-Free Experience',
                                'No ads, no interruptions — pure focus.',
                                const Color(0xFFFF6B6B),
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

              // ── Bottom action panel ───────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B2E),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
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
                      // Drag handle
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Lifetime card
                      _buildPricingCard(
                        title: 'Lifetime',
                        price: _getProduct(AdManager.productId)?.price ?? '...',
                        subtitle: 'One-time payment. Own forever.',
                        badge: 'BEST VALUE',
                        badgeColor: accentColor,
                        isSelected: _isLifetimeSelected,
                        onTap: () => setState(() => _isLifetimeSelected = true),
                      ),
                      const SizedBox(height: 10),

                      // Yearly card
                      _buildPricingCard(
                        title: 'Yearly',
                        price:
                            _getProduct(AdManager.yearlyProductId)?.price ?? '...',
                        subtitle: 'Billed annually. Cancel anytime.',
                        badge: null,
                        badgeColor: Colors.white30,
                        isSelected: !_isLifetimeSelected,
                        onTap: () => setState(() => _isLifetimeSelected = false),
                      ),
                      const SizedBox(height: 16),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _available && !_isLoading ? _buyProduct : null,
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
                                  _isLifetimeSelected
                                      ? 'Get Lifetime Access'
                                      : 'Start Yearly Plan',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Trust badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTrustBadge(
                            _isLifetimeSelected ? '✓  Lifetime' : '✓  Yearly',
                          ),
                          _dot(),
                          _buildTrustBadge(
                            _isLifetimeSelected
                                ? '✓  No subscription'
                                : '✓  Cancel anytime',
                          ),
                          _dot(),
                          _buildTrustBadge('✓  GST-ready'),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Restore
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

  // ── Helpers ────────────────────────────────────────────────────────────────
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

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const accentColor = Color(0xFFFFD700);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white24,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white54 : Colors.white38,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            // Price — fetched live from Play Store, never hardcoded
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isSelected ? accentColor : Colors.white60,
              ),
            ),
          ],
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
// Hero animation — invoice document drawing itself
// (ported from csvforge _PremiumTableAnimation, reskinned for Invoice)
// ─────────────────────────────────────────────────────────────────────────────
class _InvoiceProAnimation extends StatefulWidget {
  final double size;
  const _InvoiceProAnimation({required this.size});

  @override
  State<_InvoiceProAnimation> createState() => _InvoiceProAnimationState();
}

class _InvoiceProAnimationState extends State<_InvoiceProAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _runLoop();
  }

  void _runLoop() async {
    while (mounted) {
      try {
        await _controller.forward();
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        await _controller.reverse();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: CustomPaint(
            painter: _InvoiceDocPainter(
              animation: _animation,
              baseColor: Colors.white.withValues(alpha: 0.05),
              highlightColor: const Color(0xFF2563EB),
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: -8,
          child: Transform.rotate(
            angle: 0.35,
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD700),
              size: 40,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter: animated invoice document (diagonal reveal, same pattern as csvforge)
class _InvoiceDocPainter extends CustomPainter {
  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;

  _InvoiceDocPainter({
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final cw = size.width / 3;
    final ch = size.height / 3;
    _drawGrid(canvas, size, cw, ch, bgPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF60A5FA),
          highlightColor,
          const Color(0xFF1D4ED8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Diagonal reveal (same logic as csvforge _TablePainter)
    final maxExtent = size.width + size.height;
    final currentExtent = maxExtent * animation.value;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(currentExtent, 0)
      ..lineTo(0, currentExtent)
      ..close();

    canvas.save();
    canvas.clipPath(path);
    highlightPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    _drawGrid(canvas, size, cw, ch, highlightPaint);
    highlightPaint.maskFilter = null;
    _drawGrid(canvas, size, cw, ch, highlightPaint);
    _drawDots(canvas, size, cw, ch, highlightColor);
    canvas.restore();
  }

  void _drawGrid(
      Canvas canvas, Size size, double cw, double ch, Paint paint) {
    for (int i = 0; i <= 3; i++) {
      double x = i * cw;
      if (i == 0) x += 1;
      if (i == 3) x -= 1;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 0; i <= 3; i++) {
      double y = i * ch;
      if (i == 0) y += 1;
      if (i == 3) y -= 1;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(
      Canvas canvas, Size size, double cw, double ch, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i <= 3; i++) {
      for (int j = 0; j <= 3; j++) {
        double x = i * cw;
        double y = j * ch;
        if (i == 0) x += 1;
        if (i == 3) x -= 1;
        if (j == 0) y += 1;
        if (j == 3) y -= 1;
        canvas.drawCircle(Offset(x, y), 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InvoiceDocPainter old) => true;
}
