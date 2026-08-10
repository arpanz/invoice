import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (BulkQR Inspired Electric Blue Palette)
  static const Color primary = Color(0xFF2563EB); // Electric Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Royal Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Bright Blue
  static const Color primaryMuted = Color(0xFFEFF6FF); // Soft Tinted Blue Background
  static const Color electricAccent = Color(0xFF4F8EF7); // BulkQR Accent Blue

  // Accents
  static const Color accent = Color(0xFF10B981); // Emerald Green (Paid status)
  static const Color accentOrange = Color(0xFFF59E0B); // Amber (Unpaid status)
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
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusPaidBg = Color(0xFFECFDF5);
  static const Color statusUnpaid = Color(0xFFF59E0B);
  static const Color statusUnpaidBg = Color(0xFFFFFBEB);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0xFFFEF2F2);

  // Pro / Premium
  static const Color proGold = Color(0xFFF59E0B);
  static const Color proGoldLight = Color(0xFFFEF3C7);

  // PDF Table
  static const Color tableHeader = Color(0xFF1E293B);
  static const Color tableRowAlt = Color(0xFFF8FAFC);
  static const Color tableRowNormal = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F8EF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.05),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.03),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.28),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
