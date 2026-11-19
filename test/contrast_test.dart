import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/theme/app_colors.dart';

/// WCAG contrast of the palette's text-on-surface pairs, in both themes.
double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  tearDown(() => AppColors.isDark = false);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    test('$mode: text is readable on every surface (4.5:1)', () {
      AppColors.isDark = dark;
      final surfaces = {
        'background': AppColors.background,
        'canvas': AppColors.canvas,
        'surfaceSoft': AppColors.surfaceSoft,
        'surfaceCard': AppColors.surfaceCard,
      };
      final texts = {
        'ink': AppColors.ink,
        'body': AppColors.body,
        'muted': AppColors.muted,
        'mutedSoft': AppColors.mutedSoft,
        'slate400': AppColors.slate400,
        'error': AppColors.error,
        'statusPaid': AppColors.statusPaid,
        'statusPartiallyPaid': AppColors.statusPartiallyPaid,
        'statusOverdue': AppColors.statusOverdue,
        'brandAccent': AppColors.brandAccent,
      };
      for (final s in surfaces.entries) {
        for (final t in texts.entries) {
          expect(contrast(t.value, s.value), greaterThanOrEqualTo(4.5), reason: '${t.key} on ${s.key}');
        }
      }
    });

    test('$mode: buttons, stamps on their tints, and borders', () {
      AppColors.isDark = dark;
      expect(contrast(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.statusPaid, AppColors.statusPaidBg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.statusPartiallyPaid, AppColors.statusPartiallyPaidBg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.statusOverdue, AppColors.statusOverdueBg), greaterThanOrEqualTo(4.5));
      // Visible controls such as checkbox outlines need 3:1 (WCAG 1.4.11).
      expect(contrast(AppColors.slate300, AppColors.canvas), greaterThanOrEqualTo(3));
    });
  }
}
