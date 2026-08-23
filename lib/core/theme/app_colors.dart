import 'package:flutter/material.dart';

/// Cal.com Design System Color Palette & Semantic Tokens
class AppColors {
  AppColors._();

  // Core Brand & Action
  static const Color primary = Color(0xFF111111); // Cal.com signature black CTA
  static const Color primaryActive = Color(0xFF242424); // Pressed state
  static const Color primaryDisabled = Color(0xFFE5E7EB);
  static const Color primaryDark = Color(0xFF101010);
  static const Color primaryLight = Color(0xFF242424);
  static const Color primaryMuted = Color(0xFFF5F5F5);

  // Surfaces & Floors
  static const Color canvas = Color(0xFFFFFFFF); // Default white floor
  static const Color surfaceSoft = Color(0xFFF8F9FA); // Nav wrapper, soft dividers
  static const Color surfaceCard = Color(0xFFF5F5F5); // Light-gray card surface
  static const Color surfaceStrong = Color(0xFFE5E7EB); // Hairline alternative
  static const Color surfaceDark = Color(0xFF101010); // Signature dark card / footer
  static const Color surfaceDarkElevated = Color(0xFF1A1A1A); // Nested dark surface

  // Hairlines & Borders
  static const Color hairline = Color(0xFFE5E7EB); // 1px border tone
  static const Color hairlineSoft = Color(0xFFF3F4F6); // Soft divider

  // Text & Ink
  static const Color ink = Color(0xFF111111); // Headlines & primary type
  static const Color body = Color(0xFF374151); // Running body text
  static const Color muted = Color(0xFF6B7280); // Secondary text & subheadings
  static const Color mutedSoft = Color(0xFF898989); // Captions & fine-print
  static const Color onPrimary = Color(0xFFFFFFFF); // Text on primary CTA
  static const Color onDark = Color(0xFFFFFFFF); // Text on dark surfaces
  static const Color onDarkSoft = Color(0xFFA1A1AA); // Muted text on dark surfaces

  // Semantic & Brand Accent
  static const Color brandAccent = Color(0xFF3B82F6); // Modern electric blue (used sparingly)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Badge Pastels (for category pills & avatar fills)
  static const Color badgeOrange = Color(0xFFFB923C);
  static const Color badgePink = Color(0xFFEC4899);
  static const Color badgeViolet = Color(0xFF8B5CF6);
  static const Color badgeEmerald = Color(0xFF34D399);
  static const Color badgeBlue = Color(0xFF60A5FA);

  // Semantic Mapping / Aliases
  static const Color background = Color(0xFFF8F9FA); // App screen background
  static const Color surface = Color(0xFFFFFFFF); // White card background
  static const Color cardBorder = Color(0xFFE5E7EB); // 1px hairline card border
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textHint = Color(0xFF898989);
  static const Color electricAccent = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accent = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);

  // Neutrals Scale
  static const Color slate900 = Color(0xFF111111);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF374151);
  static const Color slate600 = Color(0xFF4B5563);
  static const Color slate500 = Color(0xFF6B7280);
  static const Color slate400 = Color(0xFF9CA3AF);
  static const Color slate300 = Color(0xFFD1D5DB);
  static const Color slate200 = Color(0xFFE5E7EB);
  static const Color slate100 = Color(0xFFF3F4F6);
  static const Color slate50 = Color(0xFFF9FAFB);

  // Status Badges & Pills
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusPaidBg = Color(0xFFECFDF5);
  static const Color statusUnpaid = Color(0xFF111111);
  static const Color statusUnpaidBg = Color(0xFFF3F4F6);
  static const Color statusPartiallyPaid = Color(0xFFD97706);
  static const Color statusPartiallyPaidBg = Color(0xFFFEF3C7);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0xFFFEF2F2);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFFFBEB);

  // Duotone Tile Tokens (Avatars & Categorization)
  static const Color squirclePurple = Color(0xFFF5F3FF);
  static const Color squirclePurpleIcon = Color(0xFF8B5CF6);
  static const Color squircleGreen = Color(0xFFECFDF5);
  static const Color squircleGreenIcon = Color(0xFF10B981);
  static const Color squircleCyan = Color(0xFFF0F9FF);
  static const Color squircleCyanIcon = Color(0xFF0284C7);
  static const Color squircleOrange = Color(0xFFFFF7ED);
  static const Color squircleOrangeIcon = Color(0xFFF97316);
  static const Color squircleTeal = Color(0xFFF0FDFA);
  static const Color squircleTealIcon = Color(0xFF0D9488);
  static const Color squircleBlue = Color(0xFFEFF6FF);
  static const Color squircleBlueIcon = Color(0xFF3B82F6);

  // Pro / Featured Badges
  static const Color proGold = Color(0xFF111111);
  static const Color proGoldLight = Color(0xFFF5F5F5);
  static const Color proBadgeBg = Color(0xFF101010);
  static const Color proBadgeBorder = Color(0xFF242424);

  // PDF Table
  static const Color tableHeader = Color(0xFF111111);
  static const Color tableRowAlt = Color(0xFFF9FAFB);
  static const Color tableRowNormal = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF242424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF101010), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFF101010), Color(0xFF242424)],
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

