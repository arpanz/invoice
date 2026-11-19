import 'package:flutter/material.dart';

/// Cal.com Design System Color Palette & Semantic Tokens
class AppColors {
  AppColors._();

  /// Set by the app root whenever the light/dark choice changes; every
  /// colour below is read through it. The root then rebuilds every widget,
  /// so screens already open pick up the new colours.
  static bool isDark = false;

  // Core Brand & Action
  static Color get primary => isDark ? const Color(0xFFF5F5F5) : const Color(0xFF111111); // Cal.com signature black CTA
  static Color get primaryActive => isDark ? const Color(0xFFE5E5E5) : const Color(0xFF242424); // Pressed state
  static Color get primaryDisabled => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
  static Color get primaryDark => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF101010);
  static Color get primaryLight => isDark ? const Color(0xFFD4D4D4) : const Color(0xFF242424);
  static Color get primaryMuted => isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5);

  // Surfaces & Floors
  static Color get canvas => isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF); // Default white floor
  static Color get surfaceSoft => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA); // Nav wrapper, soft dividers
  static Color get surfaceCard => isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5); // Light-gray card surface
  static Color get surfaceStrong => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB); // Hairline alternative
  static Color get surfaceDark => isDark ? const Color(0xFF262626) : const Color(0xFF101010); // Signature dark card / footer
  static Color get surfaceDarkElevated => isDark ? const Color(0xFF2E2E2E) : const Color(0xFF1A1A1A); // Nested dark surface

  // Hairlines & Borders
  static Color get hairline => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB); // 1px border tone
  static Color get hairlineSoft => isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6); // Soft divider

  // Text & Ink
  static Color get ink => isDark ? const Color(0xFFF2F2F2) : const Color(0xFF111111); // Headlines & primary type
  static Color get body => isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151); // Running body text
  static Color get muted => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280); // Secondary text & subheadings
  static Color get mutedSoft => isDark ? const Color(0xFF7A7A7A) : const Color(0xFF898989); // Captions & fine-print
  static Color get onPrimary => isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF); // Text on primary CTA
  static Color get onDark => isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF); // Text on dark surfaces
  static Color get onDarkSoft => isDark ? const Color(0xFFA1A1AA) : const Color(0xFFA1A1AA); // Muted text on dark surfaces

  // Semantic & Brand Accent
  static Color get brandAccent => isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6); // Modern electric blue (used sparingly)
  static Color get success => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get warning => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color get error => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

  // Badge Pastels (for category pills & avatar fills)
  static Color get badgeOrange => isDark ? const Color(0xFFFB923C) : const Color(0xFFFB923C);
  static Color get badgePink => isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899);
  static Color get badgeViolet => isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
  static Color get badgeEmerald => isDark ? const Color(0xFF34D399) : const Color(0xFF34D399);
  static Color get badgeBlue => isDark ? const Color(0xFF60A5FA) : const Color(0xFF60A5FA);

  // Semantic Mapping / Aliases
  static Color get background => isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FA); // App screen background
  static Color get surface => isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF); // White card background
  static Color get cardBorder => isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB); // 1px hairline card border
  static Color get textPrimary => isDark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);
  static Color get textSecondary => isDark ? const Color(0xFFB4BAC4) : const Color(0xFF4B5563);
  static Color get textHint => isDark ? const Color(0xFF7A7A7A) : const Color(0xFF898989);
  static Color get electricAccent => isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
  static Color get accentCyan => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get accent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get accentOrange => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color get accentRed => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

  // Neutrals Scale
  static Color get slate900 => isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111111);
  static Color get slate800 => isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1E293B);
  static Color get slate700 => isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
  static Color get slate600 => isDark ? const Color(0xFFB4BAC4) : const Color(0xFF4B5563);
  static Color get slate500 => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get slate400 => isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  static Color get slate300 => isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);
  static Color get slate200 => isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  static Color get slate100 => isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);
  static Color get slate50 => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB);

  // Status Badges & Pills
  static Color get statusPaid => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get statusPaidBg => isDark ? const Color(0xFF12291F) : const Color(0xFFECFDF5);
  static Color get statusUnpaid => isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111111);
  static Color get statusUnpaidBg => isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);
  static Color get statusPartiallyPaid => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get statusPartiallyPaidBg => isDark ? const Color(0xFF2E2410) : const Color(0xFFFEF3C7);
  static Color get statusOverdue => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  static Color get statusOverdueBg => isDark ? const Color(0xFF2D1515) : const Color(0xFFFEF2F2);
  static Color get statusPending => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color get statusPendingBg => isDark ? const Color(0xFF2B2410) : const Color(0xFFFFFBEB);

  // Duotone Tile Tokens (Avatars & Categorization)
  static Color get squirclePurple => isDark ? const Color(0xFF221C33) : const Color(0xFFF5F3FF);
  static Color get squirclePurpleIcon => isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
  static Color get squircleGreen => isDark ? const Color(0xFF12291F) : const Color(0xFFECFDF5);
  static Color get squircleGreenIcon => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get squircleCyan => isDark ? const Color(0xFF0F2433) : const Color(0xFFF0F9FF);
  static Color get squircleCyanIcon => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get squircleOrange => isDark ? const Color(0xFF2E1E10) : const Color(0xFFFFF7ED);
  static Color get squircleOrangeIcon => isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316);
  static Color get squircleTeal => isDark ? const Color(0xFF0F2826) : const Color(0xFFF0FDFA);
  static Color get squircleTealIcon => isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
  static Color get squircleBlue => isDark ? const Color(0xFF111E33) : const Color(0xFFEFF6FF);
  static Color get squircleBlueIcon => isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);

  // Pro / Featured Badges
  static Color get proGold => isDark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);
  static Color get proGoldLight => isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5);
  static Color get proBadgeBg => isDark ? const Color(0xFF262626) : const Color(0xFF101010);
  static Color get proBadgeBorder => isDark ? const Color(0xFF3A3A3A) : const Color(0xFF242424);

  // PDF Table
  static Color get tableHeader => isDark ? const Color(0xFFF2F2F2) : const Color(0xFF111111);
  static Color get tableRowAlt => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB);
  static Color get tableRowNormal => isDark ? const Color(0xFF161616) : const Color(0xFFFFFFFF);

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFFF5F5F5), Color(0xFFE5E5E5)]
        : const [Color(0xFF111111), Color(0xFF242424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get ctaGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFFF5F5F5), Color(0xFFE5E5E5)]
        : const [Color(0xFF111111), Color(0xFF1A1A1A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get heroGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF262626), Color(0xFF1F1F1F)]
        : const [Color(0xFF101010), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get proGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF262626), Color(0xFF333333)]
        : const [Color(0xFF101010), Color(0xFF242424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cal.com Subtle Drop Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 1,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> pillShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}

