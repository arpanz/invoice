import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/currency_provider.dart';
import '../core/theme/app_colors.dart';

/// Cal.com Text Input Field (`text-input` & `text-input-focused`)
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final double borderRadius;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.borderRadius = 8.0, // Cal.com rounded.md
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      focusNode: focusNode,
      textInputAction: textInputAction,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      onTap: onTap,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedSoft,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.inter(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        suffixText: suffixText,
        suffixStyle: GoogleFonts.inter(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        fillColor: AppColors.canvas,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class AmountTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? currencySymbol;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const AmountTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.currencySymbol,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    String resolvedSymbol = currencySymbol ?? '';
    if (resolvedSymbol.isEmpty) {
      try {
        resolvedSymbol = context.watch<CurrencyProvider>().currencySymbol;
      } catch (_) {
        resolvedSymbol = '\$';
      }
    }

    return CustomTextField(
      label: label,
      hint: hint ?? '0.00',
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      prefixText: '$resolvedSymbol ',
      onChanged: onChanged,
      validator: validator,
    );
  }
}

