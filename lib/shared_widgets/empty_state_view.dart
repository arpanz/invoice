import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'doodle_arrow.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered Handcrafted Hero Graphic
            Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                  ),
                ),
                // Stacked Back Card
                Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    width: 80,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.slate200,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 77, 64, 0.06),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main Front Document Card
                Container(
                  width: 84,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 77, 64, 0.10),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_rounded,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 22,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.slate200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.slate200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // High-contrast clean headline
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 21,
                letterSpacing: -0.5,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Uncluttered, graceful subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  widget.actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Stadium Pill
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ],

            // Guided Tooltip with Close Button & Doodle Arrow pointing downward
            if (showTooltip) ...[
              const SizedBox(height: 36),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 191, 165, 0.15),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.guideTooltipText!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.slate100,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showDoodleArrow) ...[
                const SizedBox(height: 6),
                const DoodleArrow(
                  width: 48,
                  height: 48,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
