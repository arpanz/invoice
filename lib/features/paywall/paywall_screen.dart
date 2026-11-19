import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../core/billing/billing_service.dart';
import '../../core/billing/free_limits.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/paywall_skyline_header.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  String _selectedProductId = BillingService.lifetimeProductId;
  late final BillingService _billing;
  late final int _grantCountAtOpen;
  bool _restoring = false;
  Timer? _restoreTimer;
  bool _closing = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _billing = context.read<BillingService>();
    _grantCountAtOpen = _billing.grantCount;
    _billing.addListener(_onBillingChanged);
    if (_billing.products.isEmpty) _billing.loadProducts();
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
    _billing.removeListener(_onBillingChanged);
    _restoreTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onBillingChanged() {
    if (!mounted || _closing) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_billing.grantCount > _grantCountAtOpen && _billing.isPro) {
      _closing = true;
      _restoreTimer?.cancel();
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pro is active. Thank you!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final error = _billing.errorMessage;
    if (error != null) {
      _billing.clearError();
      _restoreTimer?.cancel();
      setState(() => _restoring = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {});
  }

  ProductDetails? _getProduct(String productId) => _billing.productFor(productId);

  Future<void> _buyProduct() => _billing.buy(_selectedProductId);

  Future<void> _restorePurchases() async {
    setState(() => _restoring = true);
    _restoreTimer?.cancel();
    await _billing.restorePurchases();
    _restoreTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _closing) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Pro purchase was found for this Google account.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  bool get _isLoading => _billing.isLoading || _restoring;
  bool get _available => _billing.storeAvailable;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // The header is dark navy in both themes, so the status bar icons are light.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      backgroundColor: AppColors.canvas,
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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),

          _buildFeatureRow(
            Icons.receipt_long_rounded,
            'Unlimited Invoices & Estimates',
            'The free plan includes ${FreeLimits.invoicesPerMonth} of each per calendar month.',
          ),
          _buildFeatureRow(
            Icons.people_alt_rounded,
            'Unlimited Clients',
            'The free plan saves up to ${FreeLimits.savedClients} clients.',
          ),
          _buildFeatureRow(
            Icons.branding_watermark_rounded,
            'No Watermark',
            'Removes "Generated by Invoice Maker Pro" from your PDFs.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8), // rounded.md
              border: Border.all(color: AppColors.hairline),
            ),
            child: Icon(icon, color: AppColors.ink, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.muted,
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
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 1),
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
                      _getProduct(BillingService.monthlyProductId)?.price ?? '—',
                  period: '/month',
                  isSelected:
                      _selectedProductId == BillingService.monthlyProductId,
                  onTap: () => setState(
                    () => _selectedProductId = BillingService.monthlyProductId,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlanCard(
                  label: 'Lifetime',
                  price:
                      _getProduct(BillingService.lifetimeProductId)?.price ?? '—',
                  period: 'one-time',
                  badge: 'BEST VALUE',
                  isSelected: _selectedProductId == BillingService.lifetimeProductId,
                  onTap: () => setState(
                    () => _selectedProductId = BillingService.lifetimeProductId,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _available && !_isLoading ? _buyProduct : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.surfaceCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // rounded.md
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      _selectedProductId == BillingService.lifetimeProductId
                          ? 'Unlock Lifetime Access'
                          : 'Subscribe for ${_getProduct(_selectedProductId)?.price ?? 'Pro'}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            _selectedProductId == BillingService.monthlyProductId
                ? 'Renews every month at the price above until you cancel. Cancel anytime in Google Play > Payments & subscriptions.'
                : 'One payment. Pro stays active on this Google account for good.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 6),
          // Footer links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _restorePurchases,
                child: Text(
                  'Restore purchase',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              : AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w600,
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
                      ? Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              period,
              style: TextStyle(
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
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
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
