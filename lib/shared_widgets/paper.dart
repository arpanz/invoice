import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../features/invoices/models/invoice_model.dart';

/// A rubber-stamp mark ("PAID", "DUE"), set at a slight angle like a real
/// stamp. With [animate] it drops onto the page once, the app's signature
/// moment; pair it with a haptic at the call site.
class StampMark extends StatefulWidget {
  final String label;
  final Color color;
  final double fontSize;
  final bool animate;

  const StampMark({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
    this.animate = false,
  });

  /// The stamp for an invoice's payment state.
  factory StampMark.forStatus(InvoiceStatus status, {double fontSize = 10, bool animate = false}) {
    final (label, color) = stampFor(status);
    return StampMark(label: label, color: color, fontSize: fontSize, animate: animate);
  }

  static (String, Color) stampFor(InvoiceStatus status) => switch (status) {
    InvoiceStatus.paid => ('PAID', AppColors.statusPaid),
    InvoiceStatus.partiallyPaid => ('PART PAID', AppColors.statusPartiallyPaid),
    InvoiceStatus.overdue => ('OVERDUE', AppColors.statusOverdue),
    InvoiceStatus.unpaid => ('DUE', AppColors.muted),
  };

  @override
  State<StampMark> createState() => _StampMarkState();
}

class _StampMarkState extends State<StampMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void didUpdateWidget(StampMark old) {
    super.didUpdateWidget(old);
    if (widget.animate && old.label != widget.label) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stamp = Container(
      padding: EdgeInsets.symmetric(horizontal: widget.fontSize * 0.55, vertical: widget.fontSize * 0.12),
      decoration: BoxDecoration(
        border: Border.all(color: widget.color, width: math.max(1.2, widget.fontSize / 7)),
        borderRadius: BorderRadius.circular(widget.fontSize * 0.35),
      ),
      child: Text(
        widget.label,
        maxLines: 1,
        style: GoogleFonts.inter(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: widget.fontSize * 0.12,
          color: widget.color,
          height: 1.25,
        ),
      ),
    );
    return Semantics(
      label: widget.label.toLowerCase(),
      child: AnimatedBuilder(
        animation: _c,
        child: stamp,
        builder: (context, child) {
          // Lands from above, slightly over-rotated, then settles.
          final t = Curves.easeOutBack.transform(_c.value);
          final scale = 1.8 - 0.8 * t;
          final angle = (-14 + 8 * t) * math.pi / 180;
          return Opacity(
            opacity: _c.value.clamp(0, 1),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }
}

/// A paper slip: the card every document sits on, with a dashed
/// perforation border so lists read like a stack of receipts.
class PaperSlip extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dimmed;

  const PaperSlip({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.onTap,
    this.onLongPress,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = CustomPaint(
      foregroundPainter: _DashedRRectPainter(color: AppColors.hairline, radius: 12),
      child: Material(
        // Settled slips sink into the page instead of fading, so their text
        // keeps full contrast.
        color: dimmed ? AppColors.surfaceSoft : AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return PressScale(
      enabled: onTap != null,
      child: body,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  // Dashes depend only on size and radius; build them once per size.
  static final Map<(Size, double), Path> _cache = {};

  static Path _dashes(Size size, double radius) {
    return _cache.putIfAbsent((size, radius), () {
      if (_cache.length > 64) _cache.clear();
      final outline = Path()
        ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5));
      final dashes = Path();
      for (final metric in outline.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          dashes.addPath(metric.extractPath(d, math.min(d + 5, metric.length)), Offset.zero);
          d += 9;
        }
      }
      return dashes;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(_dashes(size, radius), paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color || old.radius != radius;
}

/// Shrinks its child a little while pressed and springs back, so every
/// tappable surface answers the finger at once.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const PressScale({super.key, required this.child, this.enabled = true, this.pressedScale = 0.975});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  Offset? _origin;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      // A drag is a scroll, not a press: let go so rows don't shrink while
      // the list moves.
      onPointerMove: (e) {
        if (_down && _origin != null && (e.position - _origin!).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _down ? 90 : 260),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// A short haptic that matches the weight of what just happened.
class Haptics {
  Haptics._();
  static void tap() => HapticFeedback.selectionClick();
  static void confirm() => HapticFeedback.lightImpact();
  static void stamp() => HapticFeedback.heavyImpact();
}
