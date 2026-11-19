import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/paywall/paywall_screen.dart';
import 'paper.dart';

/// The top of each tab: a small caption over a serif title, with the
/// GO PRO stamp and any [trailing] buttons on the right.
class TabHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final bool showPro;
  final List<Widget> trailing;

  const TabHeader({
    super.key,
    required this.title,
    this.caption,
    this.showPro = false,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(caption!.toUpperCase(), style: TabHeader.captionStyle),
                  ),
                Text(title, style: AppTypography.serif(fontSize: 32, color: AppColors.ink, letterSpacing: -0.8)),
              ],
            ),
          ),
          if (showPro) const ProStampButton(),
          ...trailing,
        ],
      ),
    );
  }

  /// Small spaced capitals used for captions and section labels.
  static TextStyle get captionStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: AppColors.mutedSoft,
  );
}

/// The GO PRO stamp; opens the paywall.
class ProStampButton extends StatelessWidget {
  const ProStampButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Upgrade to Pro',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.tap();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ExcludeSemantics(child: StampMark(label: 'GO PRO', color: AppColors.brandAccent)),
        ),
      ),
    );
  }
}

/// A filter pill: ink when selected, paper otherwise, with an optional count.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: () {
            if (selected) return;
            Haptics.tap();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.canvas,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: selected ? AppColors.primary : AppColors.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.onPrimary : AppColors.body,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.onPrimary.withValues(alpha: 0.7) : AppColors.mutedSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of [FilterPill]s.
class FilterRow extends StatelessWidget {
  final List<Widget> children;
  const FilterRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: children),
    );
  }
}

/// Keeps a bar (usually the filters) in reach while the list scrolls
/// under it. A hairline appears once content is underneath.
class PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  PinnedBarDelegate({required this.child, this.height = 54});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          const Spacer(),
          child,
          const Spacer(),
          AnimatedOpacity(
            opacity: overlapsContent || shrinkOffset > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ),
        ],
      ),
    );
  }

  // Colours are read at build time, so always rebuild with the theme.
  @override
  bool shouldRebuild(PinnedBarDelegate old) => true;
}

/// A label between groups in a list ("NOVEMBER 2026").
class ListSectionLabel extends StatelessWidget {
  final String text;
  const ListSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(text.toUpperCase(), style: TabHeader.captionStyle),
    );
  }
}

/// The quiet hint at the end of a list ("Swipe right to mark paid").
class ListFootnote extends StatelessWidget {
  final String text;
  const ListFootnote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 120),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedSoft),
      ),
    );
  }
}
