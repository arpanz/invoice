import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, minimal corporate paywall header featuring clean architectural
/// lines and geometric building shapes framing the sides without distracting animations.
class PaywallSkylineHeader extends StatelessWidget {
  final VoidCallback onClose;

  const PaywallSkylineHeader({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Background Minimal Corporate Cityscape Custom Paint
        const Positioned.fill(
          child: CustomPaint(
            painter: _MinimalCorporateSkylinePainter(),
          ),
        ),

        // Foreground Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, math.max(6, topPadding > 0 ? 4 : 12), 16, 26),
            child: Column(
              children: [
                // Top Bar with Tag and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Pill Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Color(0xFF60A5FA),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ENTERPRISE SUITE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Minimal Close Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Center Clean Pro Emblem
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF0F172A),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.20),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD700),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                const Text(
                  'Invoice Maker Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Built for scaling businesses. Send unlimited GST invoices, remove watermarks & access 10 pro themes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimalist corporate architectural painter rendering soft, faded geometric building shapes
/// and clean hairline lines strictly confined to the far left and right corners.
class _MinimalCorporateSkylinePainter extends CustomPainter {
  const _MinimalCorporateSkylinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Clean Corporate Gradient Background ───────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A1329), // Deep Navy Slate
          Color(0xFF0F224A), // Rich Corporate Navy
          Color(0xFF1D4ED8), // Royal Blue
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── 2. Subtle Corner-Confined Building Structures with Fade ─────────────
    _drawLeftCornerBuildings(canvas, w, h);
    _drawRightCornerBuildings(canvas, w, h);
  }

  void _drawLeftCornerBuildings(Canvas canvas, double w, double h) {
    // Strictly confined to the outer corner
    final flankWidth = math.min(w * 0.16, 62.0);

    // ── Building 1: Tall Outer Corner Monolith (Far Left) ───────────────────
    final b1Rect = Rect.fromLTWH(0, h * 0.32, flankWidth * 0.55, h * 0.62);
    final b1FillShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.02),
      ],
    ).createShader(b1Rect);

    final b1StrokeShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.16),
        Colors.white.withValues(alpha: 0.04),
      ],
    ).createShader(b1Rect);

    canvas.drawRect(b1Rect, Paint()..shader = b1FillShader);
    canvas.drawRect(
      b1Rect,
      Paint()
        ..shader = b1StrokeShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Subtle Spire / Antenna line on outer corner
    final antennaX = flankWidth * 0.25;
    canvas.drawLine(
      Offset(antennaX, h * 0.32),
      Offset(antennaX, h * 0.22),
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    // Subtle vertical hairline mullion
    canvas.drawLine(
      Offset(flankWidth * 0.35, h * 0.38),
      Offset(flankWidth * 0.35, h * 0.90),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.7,
    );

    // ── Building 2: Faded Stepped / Angled Block (Inner Left Corner) ────────
    final b2Path = Path()
      ..moveTo(flankWidth * 0.35, h * 0.52)
      ..lineTo(flankWidth, h * 0.58)
      ..lineTo(flankWidth, h * 0.94)
      ..lineTo(flankWidth * 0.35, h * 0.94)
      ..close();

    final b2Rect = Rect.fromLTWH(flankWidth * 0.35, h * 0.52, flankWidth * 0.65, h * 0.42);
    final b2FillShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF1E3A8A).withValues(alpha: 0.35),
        Colors.transparent,
      ],
    ).createShader(b2Rect);

    final b2StrokeShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFF60A5FA).withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ).createShader(b2Rect);

    canvas.drawPath(b2Path, Paint()..shader = b2FillShader);
    canvas.drawPath(
      b2Path,
      Paint()
        ..shader = b2StrokeShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Subtle horizontal hairline dividers
    for (int i = 1; i <= 2; i++) {
      final y = h * 0.64 + (i * (h * 0.10));
      canvas.drawLine(
        Offset(flankWidth * 0.35, y),
        Offset(flankWidth * 0.85, y),
        Paint()
          ..shader = b2StrokeShader
          ..strokeWidth = 0.7,
      );
    }
  }

  void _drawRightCornerBuildings(Canvas canvas, double w, double h) {
    // Strictly confined to the outer corner
    final flankWidth = math.min(w * 0.16, 62.0);
    final startX = w - flankWidth;

    // ── Building 1: Tall Outer Corner Monolith (Far Right) ──────────────────
    final b1Rect = Rect.fromLTWH(w - flankWidth * 0.55, h * 0.30, flankWidth * 0.55, h * 0.64);
    final b1FillShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.02),
        Colors.white.withValues(alpha: 0.08),
      ],
    ).createShader(b1Rect);

    final b1StrokeShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.04),
        Colors.white.withValues(alpha: 0.16),
      ],
    ).createShader(b1Rect);

    canvas.drawRect(b1Rect, Paint()..shader = b1FillShader);
    canvas.drawRect(
      b1Rect,
      Paint()
        ..shader = b1StrokeShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Subtle Spire line on outer corner
    final spireX = w - flankWidth * 0.25;
    canvas.drawLine(
      Offset(spireX, h * 0.30),
      Offset(spireX, h * 0.20),
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    // Subtle vertical hairline mullion
    canvas.drawLine(
      Offset(w - flankWidth * 0.35, h * 0.36),
      Offset(w - flankWidth * 0.35, h * 0.90),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.7,
    );

    // ── Building 2: Faded Stepped / Angled Block (Inner Right Corner) ───────
    final b2Path = Path()
      ..moveTo(startX, h * 0.58)
      ..lineTo(w - flankWidth * 0.35, h * 0.52)
      ..lineTo(w - flankWidth * 0.35, h * 0.94)
      ..lineTo(startX, h * 0.94)
      ..close();

    final b2Rect = Rect.fromLTWH(startX, h * 0.52, flankWidth * 0.65, h * 0.42);
    final b2FillShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        const Color(0xFF1E3A8A).withValues(alpha: 0.35),
      ],
    ).createShader(b2Rect);

    final b2StrokeShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        const Color(0xFF60A5FA).withValues(alpha: 0.25),
      ],
    ).createShader(b2Rect);

    canvas.drawPath(b2Path, Paint()..shader = b2FillShader);
    canvas.drawPath(
      b2Path,
      Paint()
        ..shader = b2StrokeShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Subtle horizontal hairline dividers
    for (int i = 1; i <= 2; i++) {
      final y = h * 0.64 + (i * (h * 0.10));
      canvas.drawLine(
        Offset(startX + flankWidth * 0.15, y),
        Offset(w - flankWidth * 0.35, y),
        Paint()
          ..shader = b2StrokeShader
          ..strokeWidth = 0.7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
