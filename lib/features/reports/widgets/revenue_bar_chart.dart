import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization/l10n.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/paper.dart';
import '../services/report_service.dart';

/// A grouped bar chart of Billed vs Collected per month, drawn with
/// [CustomPaint] in the paper-and-stamp style.
class RevenueBarChart extends StatefulWidget {
  final List<MonthlyRevenuePoint> points;
  final String currencyCode;
  final String currencySymbol;

  const RevenueBarChart({
    super.key,
    required this.points,
    required this.currencyCode,
    required this.currencySymbol,
  });

  @override
  State<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<RevenueBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(RevenueBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex != null && _selectedIndex! >= widget.points.length) {
      _selectedIndex = null;
    }
  }

  String _compact(double v) => CurrencyFormatter.formatCompact(
    v,
    currencyCode: widget.currencyCode,
    currencySymbol: widget.currencySymbol,
  );

  String _full(double v) => CurrencyFormatter.format(
    v,
    currencyCode: widget.currencyCode,
    currencySymbol: widget.currencySymbol,
  );

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final hasAnyValue = points.any((p) => p.billed > 0 || p.collected > 0);
    final selected = (_selectedIndex != null && _selectedIndex! < points.length)
        ? points[_selectedIndex!]
        : null;

    return PaperSlip(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.billedVsCollected,
                  style: AppTypography.serif(
                    fontSize: 19,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _LegendItem(color: AppColors.ink, label: context.l10n.billedLabel),
              const SizedBox(width: 12),
              _LegendItem(color: AppColors.statusPaid, label: context.l10n.collectedLabel),
            ],
          ),
          const SizedBox(height: 6),
          if (selected != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM yyyy', context.localeName).format(selected.month),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.billedAmount(_full(selected.billed)),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.body,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.collectedAmount(_full(selected.collected)),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusPaid,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              hasAnyValue
                  ? context.l10n.tapAMonthForDetails
                  : context.l10n.noActivityInTheseMonths,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedSoft,
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 184,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const leftAxisWidth = 48.0;
                const rightPad = 4.0;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (points.isEmpty) return;
                    final plotW =
                        constraints.maxWidth - leftAxisWidth - rightPad;
                    if (plotW <= 0) return;
                    final x = details.localPosition.dx - leftAxisWidth;
                    if (x < 0 || x > plotW) {
                      setState(() => _selectedIndex = null);
                      return;
                    }
                    final idx = (x / (plotW / points.length)).floor().clamp(
                      0,
                      points.length - 1,
                    );
                    setState(() {
                      _selectedIndex = _selectedIndex == idx ? null : idx;
                    });
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 184),
                    painter: _RevenueBarChartPainter(
                      points: points,
                      localeName: context.localeName,
                      selectedIndex: _selectedIndex,
                      formatYAxis: _compact,
                      billedColor: AppColors.ink,
                      collectedColor: AppColors.statusPaid,
                      gridColor: AppColors.hairline,
                      axisTextColor: AppColors.mutedSoft,
                      highlightBg: AppColors.surfaceCard,
                      leftAxisWidth: leftAxisWidth,
                      rightPad: rightPad,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _RevenueBarChartPainter extends CustomPainter {
  final List<MonthlyRevenuePoint> points;
  final int? selectedIndex;
  final String localeName;
  final String Function(double) formatYAxis;
  final Color billedColor;
  final Color collectedColor;
  final Color gridColor;
  final Color axisTextColor;
  final Color highlightBg;
  final double leftAxisWidth;
  final double rightPad;

  _RevenueBarChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.localeName,
    required this.formatYAxis,
    required this.billedColor,
    required this.collectedColor,
    required this.gridColor,
    required this.axisTextColor,
    required this.highlightBg,
    required this.leftAxisWidth,
    required this.rightPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPad = 8.0;
    const bottomAxisHeight = 24.0;
    final plotLeft = leftAxisWidth;
    final plotRight = size.width - rightPad;
    final plotWidth = math.max(1.0, plotRight - plotLeft);
    final plotTop = topPad;
    final plotBottom = size.height - bottomAxisHeight;
    final plotHeight = math.max(1.0, plotBottom - plotTop);

    double rawMax = 0;
    for (final p in points) {
      rawMax = math.max(rawMax, math.max(p.billed, p.collected));
    }
    final maxVal = _niceMax(rawMax);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final labelStyle = GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: axisTextColor,
    );

    // 3 horizontal grid lines: 0, 50%, 100%.
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = plotBottom - plotHeight * frac;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);

      final text = frac == 0 ? '0' : formatYAxis(maxVal * frac);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: leftAxisWidth - 6);
      tp.paint(canvas, Offset(leftAxisWidth - 6 - tp.width, y - tp.height / 2));
    }

    final slotW = plotWidth / points.length;
    final barGap = points.length > 8 ? 2.0 : 4.0;
    final maxSingleBar = 20.0;
    final barW = ((slotW * 0.68 - barGap) / 2).clamp(3.0, maxSingleBar);

    final billedPaint = Paint()..color = billedColor;
    final collectedPaint = Paint()..color = collectedColor;
    final highlightPaint = Paint()..color = highlightBg;

    final spansMultipleYears =
        points.first.month.year != points.last.month.year;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final slotLeft = plotLeft + i * slotW;
      final centerX = slotLeft + slotW / 2;

      if (selectedIndex == i) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(slotLeft + 2, plotTop, slotW - 4, plotHeight),
            const Radius.circular(6),
          ),
          highlightPaint,
        );
      }

      final pairW = barW * 2 + barGap;
      final leftBarX = centerX - pairW / 2;
      final rightBarX = leftBarX + barW + barGap;

      if (p.billed > 0) {
        final h = math.max(2.0, (p.billed / maxVal) * plotHeight);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(leftBarX, plotBottom - h, barW, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          billedPaint,
        );
      }

      if (p.collected > 0) {
        final h = math.max(2.0, (p.collected / maxVal) * plotHeight);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(rightBarX, plotBottom - h, barW, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          collectedPaint,
        );
      }

      // Show every label when <= 7 months, otherwise every 2nd (or first/last).
      final showLabel =
          points.length <= 7 ||
          i % 2 == 0 ||
          i == points.length - 1 ||
          selectedIndex == i;
      if (showLabel) {
        final fmt = spansMultipleYears && (i == 0 || p.month.month == 1)
            ? DateFormat("MMM ''yy", localeName)
            : DateFormat('MMM', localeName);
        final tp = TextPainter(
          text: TextSpan(
            text: fmt.format(p.month),
            style: labelStyle.copyWith(
              color: selectedIndex == i ? billedColor : axisTextColor,
              fontWeight: selectedIndex == i
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final dx = (centerX - tp.width / 2)
            .clamp(plotLeft, math.max(plotLeft, plotRight - tp.width))
            .toDouble();
        tp.paint(canvas, Offset(dx, plotBottom + 6));
      }
    }
  }

  double _niceMax(double v) {
    if (v <= 0) return 100;
    final exp = (math.log(v) / math.ln10).floor();
    final base = math.pow(10, exp).toDouble();
    final frac = v / base;
    if (frac <= 1.2) return 1.2 * base;
    if (frac <= 2.0) return 2.0 * base;
    if (frac <= 5.0) return 5.0 * base;
    return 10.0 * base;
  }

  @override
  bool shouldRepaint(_RevenueBarChartPainter old) =>
      old.points != points ||
      old.localeName != localeName ||
      old.selectedIndex != selectedIndex ||
      old.billedColor != billedColor ||
      old.collectedColor != collectedColor ||
      old.gridColor != gridColor ||
      old.axisTextColor != axisTextColor ||
      old.highlightBg != highlightBg;
}
