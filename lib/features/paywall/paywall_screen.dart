import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../core/localization/l10n.dart';
import '../../core/billing/billing_service.dart';
import '../../core/billing/free_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared_widgets/paper.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_animations.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedProductId = BillingService.lifetimeProductId;
  late final BillingService _billing;
  late final int _grantCountAtOpen;
  bool _restoring = false;
  Timer? _restoreTimer;
  bool _closing = false;
  Timer? _stampTimer;

  @override
  void initState() {
    super.initState();
    // The PRO stamp lands once as the page opens; the thud follows it.
    _stampTimer = Timer(const Duration(milliseconds: 520), Haptics.stamp);
    _billing = context.read<BillingService>();
    _grantCountAtOpen = _billing.grantCount;
    _billing.addListener(_onBillingChanged);
    if (_billing.products.isEmpty) _billing.loadProducts();
  }

  @override
  void dispose() {
    _billing.removeListener(_onBillingChanged);
    _restoreTimer?.cancel();
    _stampTimer?.cancel();
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
        SnackBar(
          content: Text(context.l10n.proIsActiveThankYou),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final error = _billing.localizedError(context.l10n);
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
    if (!mounted) return;
    _restoreTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _closing) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noProPurchaseWasFoundForThisGoogle),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  bool get _isLoading => _billing.isLoading || _restoring;
  bool get _available => _billing.storeAvailable;

  // ── Build ──────────────────────────────────────────────────────────────────

  bool get _lifetime => _selectedProductId == BillingService.lifetimeProductId;
  String _price(String id) => _getProduct(id)?.price ?? '—';

  void _select(String id) {
    if (_selectedProductId == id) return;
    Haptics.tap();
    setState(() => _selectedProductId = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _buildHeadline(),
                  const SizedBox(height: 22),
                  _buildReceipt(),
                  if (!_available && !_billing.isLoading) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.googlePlayPurchasesAreNotAvailableRightNow,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.statusOverdue, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            _buildBottomCta(MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.close,
            onPressed: () => Navigator.pop(context),
            icon: Icon(AppIcons.close, color: AppColors.ink, size: 24),
          ),
          const Spacer(),
          Text(context.l10n.upgrade, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.mutedSoft)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.billWithoutLimits,
          style: AppTypography.serif(fontSize: 38, color: AppColors.ink, letterSpacing: -1.2, height: 1.05),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.oneUpgradeUnlocksEveryInvoiceEveryClientAnd,
          style: GoogleFonts.inter(fontSize: 14.5, color: AppColors.muted, height: 1.45),
        ),
      ],
    );
  }

  /// What Pro includes, laid out like a receipt, with the PRO stamp on it.
  Widget _buildReceipt() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
            boxShadow: AppColors.isDark
                ? null
                : const [BoxShadow(color: Color.fromRGBO(60, 45, 20, 0.07), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice Maker Pro', style: AppTypography.serif(fontSize: 20, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(context.l10n.whatSIncluded, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.mutedSoft)),
              const SizedBox(height: 12),
              _dashedRule(),
              const SizedBox(height: 4),
              _buildFeatureRow(
                context.l10n.unlimitedInvoicesEstimates,
                context.l10n.paywallMonthlyDocumentLimit(FreeLimits.invoicesPerMonth),
              ),
              _buildFeatureRow(
                context.l10n.unlimitedClients,
                context.l10n.paywallSavedClientLimit(FreeLimits.savedClients),
              ),
              _buildFeatureRow(
                context.l10n.noWatermark,
                context.l10n.removesGeneratedByInvoiceMakerProFromYour,
              ),
              const SizedBox(height: 4),
              _dashedRule(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(context.l10n.totalHeading, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.muted)),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: AppAnimations.fast,
                    child: Text(
                      _lifetime
                          ? _price(BillingService.lifetimeProductId)
                          : context.l10n.monthlyPrice(_price(BillingService.monthlyProductId)),
                      key: ValueKey(_selectedProductId),
                      style: AppTypography.money(fontSize: 22, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 14,
          right: 16,
          child: ExcludeSemantics(
            child: StampMark(label: 'PRO', color: AppColors.brandAccent, fontSize: 20, animate: true),
          ),
        ),
      ],
    );
  }

  Widget _dashedRule() {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 8).floor();
        return Row(
          children: List.generate(
            n,
            (_) => Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: AppColors.hairline,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(AppIcons.check, color: AppColors.statusPaid, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRow({
    required String id,
    required String label,
    required String note,
    required String price,
    required String period,
    String? badge,
  }) {
    final selected = _selectedProductId == id;
    return Semantics(
      selected: selected,
      button: true,
      child: PressScale(
        child: GestureDetector(
          onTap: () => _select(id),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.defaultCurve,
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.ink : AppColors.hairline, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppAnimations.fast,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.ink : Colors.transparent,
                    border: Border.all(color: selected ? AppColors.ink : AppColors.mutedSoft, width: 1.5),
                  ),
                  child: selected ? Icon(AppIcons.check, size: 14, color: AppColors.onPrimary) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label, style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          if (badge != null) ...[
                            const SizedBox(width: 10),
                            StampMark(label: badge, color: AppColors.statusPaid, fontSize: 8.5),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(note, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: AppTypography.money(fontSize: 19, color: AppColors.ink)),
                    Text(period, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedSoft)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCta(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding > 0 ? bottomPadding : 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlanRow(
            id: BillingService.lifetimeProductId,
            label: context.l10n.lifetime,
            note: context.l10n.payOnceKeepProForGood,
            price: _price(BillingService.lifetimeProductId),
            period: context.l10n.oneTime,
            badge: context.l10n.bestValue,
          ),
          const SizedBox(height: 8),
          _buildPlanRow(
            id: BillingService.monthlyProductId,
            label: context.l10n.monthly,
            note: context.l10n.cancelAnyTimeInGooglePlay,
            price: _price(BillingService.monthlyProductId),
            period: '/month',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _available && !_isLoading
                  ? () {
                      Haptics.confirm();
                      _buyProduct();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.surfaceCard,
                disabledForegroundColor: AppColors.mutedSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
                    )
                  : Text(
                      _lifetime ? context.l10n.unlockLifetimeAccess : context.l10n.subscribeFor(_getProduct(_selectedProductId)?.price ?? 'Pro'),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lifetime
                ? context.l10n.onePaymentProStaysActiveOnThisGoogle
                : context.l10n.renewsEveryMonthAtThePriceAboveUntil,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.35),
          ),
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size(0, 40),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: Text(context.l10n.restorePurchase),
          ),
        ],
      ),
    );
  }
}
