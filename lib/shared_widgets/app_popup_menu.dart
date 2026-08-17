import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Helper for constructing beautifully styled Popup Menu Items matching the app's design system.
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
        ? AppColors.accentRed
        : (iconColor ?? AppColors.primary);
    final effectiveTextColor = isDestructive
        ? AppColors.accentRed
        : (textColor ?? AppColors.textPrimary);
    final effectiveBgColor = iconBgColor ??
        (isDestructive
            ? const Color(0xFFFEE2E2)
            : effectiveIconColor.withValues(alpha: 0.10));

    return PopupMenuItem<T>(
      value: value,
      height: subtitle != null ? 52 : 44,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: effectiveIconColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: effectiveTextColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
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
    return const PopupMenuDivider(height: 12);
  }
}
