import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

/// Cal.com Primary Action Button (`button-primary`)
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? fontSize;
  final bool useGradient;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.fontSize,
    this.useGradient = false,
    this.borderRadius = 8.0, // Cal.com rounded.md
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    final childContent = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.foregroundColor ?? AppColors.onPrimary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: widget.fontSize ?? 14,
                  fontWeight: FontWeight.w600,
                  color: widget.foregroundColor ?? AppColors.onPrimary,
                  letterSpacing: 0,
                ),
              ),
            ],
          );

    final effectiveBg = enabled
        ? (_isPressed
            ? (widget.backgroundColor != null
                ? widget.backgroundColor!.withValues(alpha: 0.85)
                : AppColors.primaryActive)
            : (widget.backgroundColor ?? AppColors.primary))
        : AppColors.primaryDisabled;

    final effectiveFg = enabled
        ? (widget.foregroundColor ?? AppColors.onPrimary)
        : AppColors.muted;

    final decoration = BoxDecoration(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: widget.backgroundColor == Colors.transparent ||
              widget.backgroundColor == Colors.white
          ? Border.all(color: AppColors.hairline, width: 1)
          : null,
      boxShadow: enabled && widget.backgroundColor == null
          ? const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]
          : null,
    );

    final buttonWidget = GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height ?? 46,
          alignment: Alignment.center,
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DefaultTextStyle(
            style: GoogleFonts.inter(
              color: effectiveFg,
              fontWeight: FontWeight.w600,
              fontSize: widget.fontSize ?? 14,
            ),
            child: childContent,
          ),
        ),
      ),
    );

    return widget.isFullWidth
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;
  }
}

/// Cal.com Secondary Action Button (`button-secondary`)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double? height;
  final double borderRadius;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = false,
    this.icon,
    this.borderColor,
    this.textColor,
    this.height,
    this.borderRadius = 8.0, // Cal.com rounded.md
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed?.call();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppColors.ink,
        backgroundColor: AppColors.canvas,
        side: BorderSide(
          color: borderColor ?? AppColors.hairline,
          width: 1.0,
        ),
        minimumSize: Size(isFullWidth ? double.infinity : 0, height ?? 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor ?? AppColors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.ink,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

