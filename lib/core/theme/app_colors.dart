import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF2563EB); // Deep Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Accent
  static const Color accent = Color(0xFF10B981); // Emerald Green (Paid status)
  static const Color accentOrange = Color(0xFFF59E0B); // Amber (Overdue)
  static const Color accentRed = Color(0xFFEF4444); // Red (Delete/Error)

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

  // Semantic
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981);
  static const Color statusPaidBg = Color(0xFFD1FAE5);
  static const Color statusUnpaid = Color(0xFFF59E0B);
  static const Color statusUnpaidBg = Color(0xFFFEF3C7);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0xFFFEE2E2);

  // Pro / Premium
  static const Color proGold = Color(0xFFF59E0B);
  static const Color proGoldLight = Color(0xFFFEF3C7);

  // PDF Table
  static const Color tableHeader = Color(0xFF1E293B);
  static const Color tableRowAlt = Color(0xFFF8FAFC);
  static const Color tableRowNormal = Color(0xFFFFFFFF);
}
