import 'package:flutter/material.dart';

/// "Paper and stamp" palette: warm paper, ink, and stamp colours.
/// Light is paper; dark is ink-dark paper.
class AppColors {
  AppColors._();

  /// Set by the app root whenever the light/dark choice changes; every
  /// colour below is read through it. The root then rebuilds every widget,
  /// so screens already open pick up the new colours.
  static bool isDark = false;

  // Core Brand & Action
  static Color get primary => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A); // Cal.com signature black CTA
  static Color get primaryActive => isDark ? const Color(0xFFDDD5C6) : const Color(0xFF34302A); // Pressed state
  static Color get primaryDisabled => isDark ? const Color(0xFF332E27) : const Color(0xFFE3DACA);
  static Color get primaryDark => isDark ? const Color(0xFFF7F1E6) : const Color(0xFF15130F);
  static Color get primaryLight => isDark ? const Color(0xFFD3CBBB) : const Color(0xFF34302A);
  static Color get primaryMuted => isDark ? const Color(0xFF26221D) : const Color(0xFFEDE6D8);

  // Surfaces & Floors
  static Color get canvas => isDark ? const Color(0xFF1E1B17) : const Color(0xFFFFFDF8); // Default white floor
  static Color get surfaceSoft => isDark ? const Color(0xFF191714) : const Color(0xFFF8F4EA); // Nav wrapper, soft dividers
  static Color get surfaceCard => isDark ? const Color(0xFF26221D) : const Color(0xFFF1EBDF); // Light-gray card surface
  static Color get surfaceStrong => isDark ? const Color(0xFF332E27) : const Color(0xFFE3DACA); // Hairline alternative
  static Color get surfaceDark => isDark ? const Color(0xFF2A2621) : const Color(0xFF1F1D1A); // Signature dark card / footer
  static Color get surfaceDarkElevated => isDark ? const Color(0xFF36312A) : const Color(0xFF2C2924); // Nested dark surface

  // Hairlines & Borders
  static Color get hairline => isDark ? const Color(0xFF332E27) : const Color(0xFFE3DACA); // 1px border tone
  static Color get hairlineSoft => isDark ? const Color(0xFF2A2621) : const Color(0xFFEDE6D8); // Soft divider

  // Text & Ink
  static Color get ink => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A); // Headlines & primary type
  static Color get body => isDark ? const Color(0xFFD3CBBB) : const Color(0xFF3E3A33); // Running body text
  static Color get muted => isDark ? const Color(0xFFA39A8A) : const Color(0xFF6F675A); // Secondary text & subheadings
  static Color get mutedSoft => isDark ? const Color(0xFF978F80) : const Color(0xFF6B6253); // Captions & fine-print
  static Color get onPrimary => isDark ? const Color(0xFF1A1814) : const Color(0xFFFBF8F1); // Text on primary CTA
  static Color get onDark => isDark ? const Color(0xFFF4EEE2) : const Color(0xFFFBF8F1); // Text on dark surfaces
  static Color get onDarkSoft => isDark ? const Color(0xFFA39A8A) : const Color(0xFFB5AC9C); // Muted text on dark surfaces

  // Semantic & Brand Accent
  static Color get brandAccent => isDark ? const Color(0xFF8EAEDB) : const Color(0xFF2B4C7E); // Modern electric blue (used sparingly)
  static Color get success => isDark ? const Color(0xFF7FB98D) : const Color(0xFF2E6B3F);
  static Color get warning => isDark ? const Color(0xFFDDA650) : const Color(0xFF8F5A0C);
  static Color get error => isDark ? const Color(0xFFE3836C) : const Color(0xFFB23A22);

  // Badge Pastels (for category pills & avatar fills)
  static Color get badgeOrange => isDark ? const Color(0xFFE09A63) : const Color(0xFFC26A2E);
  static Color get badgePink => isDark ? const Color(0xFFD98AA5) : const Color(0xFFA8466B);
  static Color get badgeViolet => isDark ? const Color(0xFFB9A0D6) : const Color(0xFF6B4E8A);
  static Color get badgeEmerald => isDark ? const Color(0xFF7FB98D) : const Color(0xFF2E6B3F);
  static Color get badgeBlue => isDark ? const Color(0xFF8EAEDB) : const Color(0xFF2B4C7E);

  // Semantic Mapping / Aliases
  static Color get background => isDark ? const Color(0xFF14120F) : const Color(0xFFF4EFE4); // App screen background
  static Color get surface => isDark ? const Color(0xFF1E1B17) : const Color(0xFFFFFDF8); // White card background
  static Color get cardBorder => isDark ? const Color(0xFF332E27) : const Color(0xFFE3DACA); // 1px hairline card border
  static Color get textPrimary => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A);
  static Color get textSecondary => isDark ? const Color(0xFFB9B0A0) : const Color(0xFF5A5347);
  static Color get textHint => isDark ? const Color(0xFF978F80) : const Color(0xFF6B6253);
  static Color get electricAccent => isDark ? const Color(0xFF8EAEDB) : const Color(0xFF2B4C7E);
  static Color get accentCyan => isDark ? const Color(0xFF7FB3BD) : const Color(0xFF2F6872);
  static Color get accent => isDark ? const Color(0xFF7FB98D) : const Color(0xFF2E6B3F);
  static Color get accentOrange => isDark ? const Color(0xFFDDA650) : const Color(0xFF8F5A0C);
  static Color get accentRed => isDark ? const Color(0xFFE3836C) : const Color(0xFFB23A22);

  // Neutrals Scale
  static Color get slate900 => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A);
  static Color get slate800 => isDark ? const Color(0xFFE3DACA) : const Color(0xFF2C2924);
  static Color get slate700 => isDark ? const Color(0xFFD3CBBB) : const Color(0xFF3E3A33);
  static Color get slate600 => isDark ? const Color(0xFFB9B0A0) : const Color(0xFF5A5347);
  static Color get slate500 => isDark ? const Color(0xFFA39A8A) : const Color(0xFF6F675A);
  static Color get slate400 => isDark ? const Color(0xFF978F80) : const Color(0xFF6B6253);
  static Color get slate300 => isDark ? const Color(0xFF6F675A) : const Color(0xFF9A8F7C);
  static Color get slate200 => isDark ? const Color(0xFF3E3A33) : const Color(0xFFE3DACA);
  static Color get slate100 => isDark ? const Color(0xFF2A2621) : const Color(0xFFEDE6D8);
  static Color get slate50 => isDark ? const Color(0xFF1E1B17) : const Color(0xFFF8F4EA);

  // Status Badges & Pills
  static Color get statusPaid => isDark ? const Color(0xFF7FB98D) : const Color(0xFF2E6B3F);
  static Color get statusPaidBg => isDark ? const Color(0xFF1F2B21) : const Color(0xFFE3EEDF);
  static Color get statusUnpaid => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A);
  static Color get statusUnpaidBg => isDark ? const Color(0xFF2A2621) : const Color(0xFFEDE6D8);
  static Color get statusPartiallyPaid => isDark ? const Color(0xFFDDA650) : const Color(0xFF8F5A0C);
  static Color get statusPartiallyPaidBg => isDark ? const Color(0xFF2F2617) : const Color(0xFFF6E7C8);
  static Color get statusOverdue => isDark ? const Color(0xFFE3836C) : const Color(0xFFB23A22);
  static Color get statusOverdueBg => isDark ? const Color(0xFF33201B) : const Color(0xFFF6DDD5);
  static Color get statusPending => isDark ? const Color(0xFFDDA650) : const Color(0xFF8F5A0C);
  static Color get statusPendingBg => isDark ? const Color(0xFF2F2617) : const Color(0xFFF6E7C8);

  // Icon tiles. In the paper look every decorative tile is the same quiet
  // card with an ink icon; only green keeps its colour because it means
  // "paid / taxable / in stock" wherever it appears.
  static Color get squirclePurple => surfaceCard;
  static Color get squirclePurpleIcon => ink;
  static Color get squircleGreen => isDark ? const Color(0xFF1F2B21) : const Color(0xFFE3EEDF);
  static Color get squircleGreenIcon => isDark ? const Color(0xFF7FB98D) : const Color(0xFF2E6B3F);
  static Color get squircleCyan => surfaceCard;
  static Color get squircleCyanIcon => ink;
  static Color get squircleOrange => surfaceCard;
  static Color get squircleOrangeIcon => ink;
  static Color get squircleTeal => surfaceCard;
  static Color get squircleTealIcon => ink;
  static Color get squircleBlue => surfaceCard;
  static Color get squircleBlueIcon => ink;

  // Pro / Featured Badges
  static Color get proGold => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A);
  static Color get proGoldLight => isDark ? const Color(0xFF26221D) : const Color(0xFFEDE6D8);
  static Color get proBadgeBg => isDark ? const Color(0xFF2A2621) : const Color(0xFF1F1D1A);
  static Color get proBadgeBorder => isDark ? const Color(0xFF3E3A33) : const Color(0xFF34302A);

  // PDF Table
  static Color get tableHeader => isDark ? const Color(0xFFEFE8DA) : const Color(0xFF1F1D1A);
  static Color get tableRowAlt => isDark ? const Color(0xFF191714) : const Color(0xFFF8F4EA);
  static Color get tableRowNormal => isDark ? const Color(0xFF1E1B17) : const Color(0xFFFFFDF8);

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFFEFE8DA), Color(0xFFDDD5C6)]
        : const [Color(0xFF1F1D1A), Color(0xFF34302A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get ctaGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFFEFE8DA), Color(0xFFDDD5C6)]
        : const [Color(0xFF1F1D1A), Color(0xFF2C2924)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get heroGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF2A2621), Color(0xFF221F1A)]
        : const [Color(0xFF1F1D1A), Color(0xFF2C2924)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get proGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF2A2621), Color(0xFF36312A)]
        : const [Color(0xFF1F1D1A), Color(0xFF34302A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cal.com Subtle Drop Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(60, 45, 20, 0.04),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(60, 45, 20, 0.02),
      blurRadius: 1,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color.fromRGBO(60, 45, 20, 0.12),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(60, 45, 20, 0.08),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> pillShadow = [
    BoxShadow(
      color: Color.fromRGBO(60, 45, 20, 0.06),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}

