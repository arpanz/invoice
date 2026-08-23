import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Cal.com Design System Typography & Theme Configuration
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        TextTheme(
          // Display XL - Cal Sans style display head
          displayLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -1.2,
            height: 1.1,
          ),
          // Display LG - Section heads
          displayMedium: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.9,
            height: 1.15,
          ),
          // Display SM - Card titles & prominent stats
          displaySmall: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.6,
            height: 1.2,
          ),
          // Headline Large - Card group titles
          headlineLarge: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.4,
            height: 1.3,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.2,
            height: 1.35,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0,
            height: 1.4,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0,
          ),
          titleSmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.2,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.body,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.body,
            height: 1.5,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0,
          ),
          labelMedium: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
            letterSpacing: 0,
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedSoft,
            letterSpacing: 0.2,
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.surfaceCard,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.body,
          onSecondary: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.error,
          onError: Colors.white,
          outline: AppColors.hairline,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // rounded.lg
            side: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.canvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // rounded.md
            borderSide: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mutedSoft,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // rounded.md
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.canvas,
            foregroundColor: AppColors.ink,
            elevation: 0,
            side: const BorderSide(color: AppColors.hairline, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // full circle
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.canvas,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedSoft,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.hairlineSoft,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shadowColor: const Color.fromRGBO(0, 0, 0, 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded.xl
            side: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.body,
            height: 1.45,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: const Color.fromRGBO(0, 0, 0, 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          modalBarrierColor: Color.fromRGBO(0, 0, 0, 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          showDragHandle: false,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          shadowColor: const Color.fromRGBO(0, 0, 0, 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          headerBackgroundColor: AppColors.primary,
          headerForegroundColor: Colors.white,
          headerHeadlineStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
          headerHelpStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          weekdayStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
          dayStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
          todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
          yearStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.canvas,
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.hairline, width: 1),
          ),
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          dayPeriodShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceDark,
          contentTextStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.onDark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceCard,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // rounded.pill
            side: const BorderSide(color: Colors.transparent),
          ),
        ),
      );
}

