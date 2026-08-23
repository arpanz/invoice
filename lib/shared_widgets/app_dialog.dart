import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

enum AppDialogVariant {
  danger,
  primary,
  warning,
  success,
  info,
}

/// Cal.com Clean SaaS Dialog Modal
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.variant = AppDialogVariant.primary,
    this.icon,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.showCancel = true,
  });

  final String title;
  final String message;
  final AppDialogVariant variant;
  final IconData? icon;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool showCancel;

  Color get _badgeBg => switch (variant) {
        AppDialogVariant.danger => AppColors.statusOverdueBg,
        AppDialogVariant.primary => AppColors.surfaceCard,
        AppDialogVariant.warning => AppColors.statusPendingBg,
        AppDialogVariant.success => AppColors.statusPaidBg,
        AppDialogVariant.info => AppColors.squircleCyan,
      };

  Color get _badgeIconColor => switch (variant) {
        AppDialogVariant.danger => AppColors.error,
        AppDialogVariant.primary => AppColors.ink,
        AppDialogVariant.warning => AppColors.warning,
        AppDialogVariant.success => AppColors.success,
        AppDialogVariant.info => AppColors.squircleCyanIcon,
      };

  IconData get _defaultIcon => switch (variant) {
        AppDialogVariant.danger => Icons.delete_outline_rounded,
        AppDialogVariant.primary => Icons.check_circle_outline_rounded,
        AppDialogVariant.warning => Icons.warning_amber_rounded,
        AppDialogVariant.success => Icons.check_rounded,
        AppDialogVariant.info => Icons.info_outline_rounded,
      };

  Color get _confirmBg => isDestructive || variant == AppDialogVariant.danger
      ? AppColors.error
      : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16), // rounded.xl
          border: Border.all(color: AppColors.hairline, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.10),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge Header
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon ?? _defaultIcon,
                    color: _badgeIconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title in Cal Sans / Inter 600
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              if (message.isNotEmpty)
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),

              // Optional Custom Body Content
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],

              const SizedBox(height: 22),

              // Actions
              Row(
                children: [
                  if (showCancel) ...[
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: onCancel ?? () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.hairline, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // rounded.md
                            ),
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            cancelLabel,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onConfirm ?? () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confirmBg,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // rounded.md
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          confirmLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATIC CONVENIENCE METHODS
  // ---------------------------------------------------------------------------

  /// Show a generic styled confirmation dialog with soft backdrop blur.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    AppDialogVariant variant = AppDialogVariant.primary,
    IconData? icon,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => AppDialog(
        title: title,
        message: message,
        variant: variant,
        icon: icon,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3 * curved.value, sigmaY: 3 * curved.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Show a standardized modern Delete confirmation dialog.
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) {
    return showConfirmation(
      context: context,
      title: title,
      message: message,
      variant: AppDialogVariant.danger,
      icon: Icons.delete_outline_rounded,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: true,
    );
  }

  /// Show a standardized Convert Estimate confirmation dialog.
  static Future<bool?> showConvertEstimate({
    required BuildContext context,
    required String estimateNumber,
    required String clientName,
  }) {
    return showConfirmation(
      context: context,
      title: 'Convert to Invoice?',
      message:
          'This will generate an active invoice from $estimateNumber for $clientName and mark this estimate as Converted.',
      variant: AppDialogVariant.primary,
      icon: Icons.receipt_long_rounded,
      confirmLabel: 'Convert to Invoice',
      cancelLabel: 'Cancel',
    );
  }

  /// Show a modern, interactive Partial Payment dialog with quick percentage chips.
  static Future<double?> showPartialPayment({
    required BuildContext context,
    required String documentNumber,
    required double grandTotal,
    required String currencySymbol,
    double currentPaidAmount = 0.0,
  }) {
    final defaultAmount = currentPaidAmount > 0
        ? currentPaidAmount
        : (grandTotal > 0 ? (grandTotal * 0.5) : 0.0);

    return showGeneralDialog<double>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Partial Payment',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        final ctrl = TextEditingController(
          text: defaultAmount > 0
              ? defaultAmount.toStringAsFixed(2).replaceAll('.00', '')
              : '',
        );

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final parsedVal = double.tryParse(ctrl.text.trim()) ?? 0.0;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16), // rounded.xl
                  border: Border.all(color: AppColors.hairline, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.10),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with payment badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.payments_outlined,
                                color: AppColors.ink,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Payment',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  documentNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Grand Total Reference Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice Total',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '$currencySymbol${grandTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Percentage Chips (nav-pill style)
                      if (grandTotal > 0) ...[
                        Row(
                          children: [0.25, 0.50, 0.75, 1.0].map((pct) {
                            final targetAmount = grandTotal * pct;
                            final isSel = (parsedVal - targetAmount).abs() < 0.01;
                            final label = pct == 1.0 ? '100% (Full)' : '${(pct * 100).toInt()}%';

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9999),
                                  onTap: () {
                                    setDialogState(() {
                                      ctrl.text = targetAmount
                                          .toStringAsFixed(2)
                                          .replaceAll('.00', '');
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.primary
                                          : AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(9999), // pill
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.primary
                                            : AppColors.hairline,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSel ? AppColors.onPrimary : AppColors.body,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Amount Input Field
                      TextField(
                        controller: ctrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (_) => setDialogState(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount Paid',
                          prefixText: '$currencySymbol ',
                          prefixStyle: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          hintText: '0.00',
                          filled: true,
                          fillColor: AppColors.canvas,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.hairline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.hairline, width: 1.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  foregroundColor: AppColors.ink,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amount = double.tryParse(ctrl.text.trim()) ?? 0.0;
                                  Navigator.pop(ctx, amount);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Save Payment',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3 * curved.value, sigmaY: 3 * curved.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

