import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

enum AppDialogVariant {
  danger,
  primary,
  warning,
  success,
  info,
}

/// A modern, cohesive popup dialog matching the app's royal blue & slate design system.
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
        AppDialogVariant.danger => const Color(0xFFFEE2E2),
        AppDialogVariant.primary => AppColors.squircleBlue,
        AppDialogVariant.warning => AppColors.squircleOrange,
        AppDialogVariant.success => AppColors.squircleGreen,
        AppDialogVariant.info => AppColors.squircleCyan,
      };

  Color get _badgeIconColor => switch (variant) {
        AppDialogVariant.danger => AppColors.accentRed,
        AppDialogVariant.primary => AppColors.primary,
        AppDialogVariant.warning => AppColors.squircleOrangeIcon,
        AppDialogVariant.success => AppColors.squircleGreenIcon,
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
      ? AppColors.accentRed
      : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge Header
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    icon ?? _defaultIcon,
                    color: _badgeIconColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.slate600,
                  ),
                ),

              // Optional Custom Body Content
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  if (showCancel) ...[
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: onCancel ?? () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: AppColors.slate700,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            cancelLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onConfirm ?? () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confirmBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
      barrierColor: AppColors.slate900.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
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
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
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
      barrierColor: AppColors.slate900.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.14),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with payment badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.squircleOrange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.payments_outlined,
                                color: AppColors.squircleOrangeIcon,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Record Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  documentNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate500,
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
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Invoice Total',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$currencySymbol${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Percentage Chips
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
                                  borderRadius: BorderRadius.circular(10),
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
                                          : AppColors.slate100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.primary
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSel ? Colors.white : AppColors.slate700,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount Paid',
                          prefixText: '$currencySymbol ',
                          prefixStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          hintText: '0.00',
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: AppColors.slate700,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amount = double.tryParse(ctrl.text.trim()) ?? 0.0;
                                  Navigator.pop(ctx, amount);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Payment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
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
