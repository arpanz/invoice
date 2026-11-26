import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../l10n/gen/app_localizations_en.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/paper.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/services/invoice_render_service.dart';

/// One thing a new user still has to do before their invoices look finished.
enum SetupStep { logo, address, taxId, payment, signature, firstInvoice }

class SetupItem {
  final SetupStep step;
  final String? taxIdLabel;
  final IconData icon;
  final bool done;

  const SetupItem({
    required this.step,
    required this.icon,
    required this.done,
    this.taxIdLabel,
  });

  String get label => localizedLabel(AppLocalizationsEn());

  String localizedLabel(AppLocalizations l10n) => switch (step) {
    SetupStep.logo => l10n.addYourLogo,
    SetupStep.address => l10n.addYourAddress,
    SetupStep.taxId => l10n.addYourTaxId(
      taxIdLabel == null ? l10n.taxId : l10n.catalogLabel(taxIdLabel!),
    ),
    SetupStep.payment => l10n.addHowClientsPayYou,
    SetupStep.signature => l10n.addYourSignature,
    SetupStep.firstInvoice => l10n.makeYourFirstInvoice,
  };
}

/// The "Finish setting up" list, worked out from saved settings only, so it
/// can be tested without a screen.
class SetupChecklist {
  /// Set once the user closes the card; it never comes back after that.
  static const dismissedKey = 'setup_checklist_dismissed';

  final List<SetupItem> items;
  final bool dismissed;

  const SetupChecklist({required this.items, this.dismissed = false});

  int get doneCount => items.where((i) => i.done).length;
  int get total => items.length;
  bool get allDone => doneCount == total;

  /// Hidden once closed or once there is nothing left to do.
  bool get isVisible => !dismissed && !allDone;

  /// [isVisible] for a card that leaves out the first-invoice row: with
  /// only that row left there would be nothing to show.
  bool isVisibleWithout(SetupStep step) =>
      isVisible && items.any((i) => !i.done && i.step != step);

  /// Only asks for what will actually print: a tax ID when tax is charged,
  /// payment details and a signature when the default design shows them.
  static SetupChecklist compute({
    required String? Function(String key) pref,
    required InvoiceCustomizationConfig design,
    required int invoiceCount,
    required double taxRate,
    String? taxIdLabel,
    bool dismissed = false,
  }) {
    bool has(String key) => (pref(key) ?? '').trim().isNotEmpty;
    return SetupChecklist(
      dismissed: dismissed,
      items: [
        SetupItem(step: SetupStep.logo, icon: AppIcons.image, done: has('biz_logo_path')),
        SetupItem(
          step: SetupStep.address,
          icon: AppIcons.location,
          done: has('biz_address'),
        ),
        if (taxRate > 0)
          SetupItem(step: SetupStep.taxId, taxIdLabel: taxIdLabel, icon: AppIcons.badge, done: has('biz_gstin')),
        if (design.showUpiDetails || design.showBankDetails)
          SetupItem(
            step: SetupStep.payment,
            icon: AppIcons.bank,
            done: has('biz_upi') || has('biz_account'),
          ),
        if (design.showSignature)
          SetupItem(
            step: SetupStep.signature,
            icon: AppIcons.draw,
            done: has('biz_signature_path'),
          ),
        SetupItem(
          step: SetupStep.firstInvoice,
          icon: AppIcons.receipt,
          done: invoiceCount > 0,
        ),
      ],
    );
  }

  /// Reads the profile and the default design the same way a new invoice
  /// does, so the list matches what the first PDF will show.
  static SetupChecklist fromPrefs(
    SharedPreferences prefs, {
    required int invoiceCount,
    required double taxRate,
    required String taxIdLabel,
  }) {
    return compute(
      pref: prefs.getString,
      design: InvoiceRenderService.designFrom(
        defaultConfig: prefs.getString('default_invoice_customization'),
        defaultTheme: prefs.getString('default_pdf_theme'),
      ),
      invoiceCount: invoiceCount,
      taxRate: taxRate,
      taxIdLabel: taxIdLabel,
      dismissed: prefs.getBool(dismissedKey) ?? false,
    );
  }

  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dismissedKey, true);
  }
}

/// A paper card on the dashboard listing what is left to set up. Done items
/// drop off so the card shrinks as the user goes; the bar shows progress.
class SetupChecklistCard extends StatelessWidget {
  final SetupChecklist checklist;
  final ValueChanged<SetupStep> onOpen;
  final VoidCallback onDismissed;

  /// Off when a create button already sits right next to the card; the
  /// item still counts towards "n of m done".
  final bool showFirstInvoice;

  const SetupChecklistCard({
    super.key,
    required this.checklist,
    required this.onOpen,
    required this.onDismissed,
    this.showFirstInvoice = true,
  });

  Future<void> _dismiss() async {
    Haptics.tap();
    try {
      await SetupChecklist.dismiss();
    } catch (e) {
      debugPrint('Could not save the checklist dismissal: $e');
    }
    onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final todo = checklist.items
        .where((i) => !i.done && (showFirstInvoice || i.step != SetupStep.firstInvoice))
        .toList();
    final progress = checklist.total == 0 ? 0.0 : checklist.doneCount / checklist.total;

    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.l10n.finishSettingUp, style: AppTypography.serif(fontSize: 19, color: AppColors.ink)),
              ),
              IconButton(
                tooltip: context.l10n.hide,
                onPressed: _dismiss,
                visualDensity: VisualDensity.compact,
                icon: Icon(AppIcons.close, color: AppColors.muted, size: 18),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Text(
                  context.l10n.setupProgress(checklist.doneCount, checklist.total),
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          Positioned.fill(child: ColoredBox(color: AppColors.hairline)),
                          AnimatedFractionallySizedBox(
                            duration: AppAnimations.slow,
                            curve: AppAnimations.defaultCurve,
                            widthFactor: progress,
                            heightFactor: 1,
                            alignment: Alignment.centerLeft,
                            child: ColoredBox(color: AppColors.statusPaid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final item in todo) _row(context, item),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, SetupItem item) {
    return InkWell(
      onTap: () {
        Haptics.tap();
        onOpen(item.step);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
        child: Row(
          // Centred so a label that wraps to two lines keeps the icon and
          // chevron level with it.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
              child: Icon(item.icon, color: AppColors.ink, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.localizedLabel(context.l10n),
                // Long tax ID names ("Unified Social Credit Code") need room;
                // cutting them off would hide what to add.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
              ),
            ),
            Icon(AppIcons.chevronRight, color: AppColors.mutedSoft, size: 18),
          ],
        ),
      ),
    );
  }
}
