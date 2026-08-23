import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// Helper for constructing beautifully styled Popup Menu Items matching Cal.com design system.
class AppPopupMenuItem {
  AppPopupMenuItem._();

  /// Create a standardized PopupMenuItem with an icon, title, and optional semantic color styling.
  static PopupMenuItem<T> item<T>({
    required T value,
    required String title,
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    Color? textColor,
    bool isDestructive = false,
    String? subtitle,
  }) {
    final effectiveIconColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.ink);
    final effectiveTextColor = isDestructive
        ? AppColors.error
        : (textColor ?? AppColors.ink);
    final effectiveBgColor = iconBgColor ??
        (isDestructive
            ? AppColors.statusOverdueBg
            : AppColors.surfaceCard);

    return PopupMenuItem<T>(
      value: value,
      height: subtitle != null ? 52 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(6), // rounded.sm
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: effectiveIconColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Create a subtle, refined divider between popup menu item groups.
  static PopupMenuEntry<T> divider<T>() {
    return const PopupMenuDivider(height: 8);
  }
}

