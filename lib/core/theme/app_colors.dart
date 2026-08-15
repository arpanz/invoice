import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Modern Royal Blue Palette matching designs)
  static const Color primary = Color(0xFF2563EB); // Royal Electric Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Medium Vibrant Blue
  static const Color primaryMuted = Color(0xFFEFF6FF); // Soft Blue Tint Background
  static const Color electricAccent = Color(0xFF3B82F6); // Vibrant Blue Accent
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan Accent

  // Squircle Duotone Icon Tile Tokens
  static const Color squirclePurple = Color(0xFFF3E8FF);
  static const Color squirclePurpleIcon = Color(0xFF9333EA);
  static const Color squircleGreen = Color(0xFFDCFCE7);
  static const Color squircleGreenIcon = Color(0xFF16A34A);
  static const Color squircleCyan = Color(0xFFE0F2FE);
  static const Color squircleCyanIcon = Color(0xFF0284C7);
  static const Color squircleOrange = Color(0xFFFEF3C7);
  static const Color squircleOrangeIcon = Color(0xFFD97706);
  static const Color squircleTeal = Color(0xFFCCFBF1);
  static const Color squircleTealIcon = Color(0xFF0F766E);
  static const Color squircleBlue = Color(0xFFEFF6FF);
  static const Color squircleBlueIcon = Color(0xFF2563EB);

  // Accents
  static const Color accent = Color(0xFF10B981); // Emerald Green (Paid status)
  static const Color accentOrange = Color(0xFFF59E0B); // Amber (Pending status)
  static const Color accentRed = Color(0xFFEF4444); // Red (Overdue/Delete)

  // Neutrals
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Semantic Colors
  static const Color background = Color(0xFFF4F7FB); // Clean soft blue-grey canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE6ECF5);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusPaidBg = Color(0xFFECFDF5);
  static const Color statusUnpaid = Color(0xFF2563EB);
  static const Color statusUnpaidBg = Color(0xFFEFF6FF);
  static const Color statusPartiallyPaid = Color(0xFFD97706);
  static const Color statusPartiallyPaidBg = Color(0xFFFEF3C7);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0xFFFEF2F2);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFFFBEB);

  // Pro / Premium
  static const Color proGold = Color(0xFFF59E0B);
  static const Color proGoldLight = Color(0xFFFEF3C7);
  static const Color proBadgeBg = Color(0xFFFFF7ED);
  static const Color proBadgeBorder = Color(0xFFFFEDD5);

  // PDF Table
  static const Color tableHeader = Color(0xFF2563EB);
  static const Color tableRowAlt = Color(0xFFF8FAFC);
  static const Color tableRowNormal = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.04),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.02),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.25),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
