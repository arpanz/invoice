import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'doodle_arrow.dart';

/// Cal.com Minimalist SaaS Empty State View
class EmptyStateView extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDarkBackground;
  final String? guideTooltipText;
  final VoidCallback? onDismissTooltip;
  final bool showDoodleArrow;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isDarkBackground = false,
    this.guideTooltipText,
    this.onDismissTooltip,
    this.showDoodleArrow = false,
  });

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  bool _tooltipDismissed = false;

  @override
  Widget build(BuildContext context) {
    final bool showTooltip =
        widget.guideTooltipText != null && !_tooltipDismissed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cal.com Minimal Product UI Fragment / Document Graphic
            Container(
              width: 88,
              height: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12), // rounded.lg
                border: Border.all(
                  color: AppColors.hairline,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 14,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        width: 18,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.hairlineSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 24,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cal Sans Style Display Title
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: -0.4,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Body text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  widget.actionLabel!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // rounded.md
                  ),
                  elevation: 0,
                ),
              ),
            ],

            // Guided Tooltip with Close Button
            if (showTooltip) ...[
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(9999), // pill
                  border: Border.all(
                    color: AppColors.hairline,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.guideTooltipText!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _tooltipDismissed = true);
                        widget.onDismissTooltip?.call();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceCard,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showDoodleArrow) ...[
                const SizedBox(height: 6),
                const DoodleArrow(
                  width: 44,
                  height: 44,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

