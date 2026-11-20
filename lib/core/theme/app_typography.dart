import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_icons.dart';
import 'theme_controller.dart';

/// "Paper and stamp" typography: Fraunces (serif) for titles and amounts,
/// Inter for everything else.
class AppTypography {
  AppTypography._();

  /// Tabular font feature for millimeter-precision aligned financial figures
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Serif display style for titles, hero numbers and stamps.
  static TextStyle serif({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.3,
    double? height,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.ink,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Money amounts: serif with tabular figures so columns line up.
  static TextStyle money({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.ink,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures,
    );
  }

  /// Invoice and estimate numbers and codes, in Inter with tabular figures
  /// (bundled, so it works offline).
  static TextStyle monoCode({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.muted,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures,
    );
  }

  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        TextTheme(
          // Display XL - Cal Sans style display head
          displayLarge: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.8,
            height: 1.1,
            fontFeatures: tabularFigures,
          ),
          // Display LG - Section heads
          displayMedium: GoogleFonts.fraunces(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.6,
            height: 1.15,
            fontFeatures: tabularFigures,
          ),
          // Display SM - Card titles & prominent stats
          displaySmall: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.6,
            height: 1.2,
            fontFeatures: tabularFigures,
          ),
          // Headline Large - Card group titles
          headlineLarge: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.4,
            height: 1.3,
            fontFeatures: tabularFigures,
          ),
          headlineMedium: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.2,
            height: 1.35,
            fontFeatures: tabularFigures,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0,
            height: 1.4,
            fontFeatures: tabularFigures,
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

  /// The app theme for the current [AppColors.isDark] setting.
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        // Android: a quiet fade-forwards that keeps predictive back. iOS keeps
        // its swipe-back slide.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        splashFactory: InkSparkle.splashFactory,
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
        // Every role is set: anything left out falls back to Material's
        // purple-tinted defaults, which is how switches, menus and chips
        // end up off-theme.
        colorScheme: ColorScheme(
          brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.surfaceCard,
          onPrimaryContainer: AppColors.ink,
          primaryFixed: AppColors.surfaceCard,
          onPrimaryFixed: AppColors.ink,
          secondary: AppColors.ink,
          onSecondary: AppColors.onPrimary,
          secondaryContainer: AppColors.surfaceCard,
          onSecondaryContainer: AppColors.ink,
          tertiary: AppColors.brandAccent,
          onTertiary: AppColors.onPrimary,
          tertiaryContainer: AppColors.surfaceCard,
          onTertiaryContainer: AppColors.brandAccent,
          error: AppColors.error,
          onError: AppColors.onPrimary,
          errorContainer: AppColors.statusOverdueBg,
          onErrorContainer: AppColors.statusOverdue,
          surface: AppColors.canvas,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          surfaceDim: AppColors.background,
          surfaceBright: AppColors.canvas,
          surfaceContainerLowest: AppColors.canvas,
          surfaceContainerLow: AppColors.canvas,
          surfaceContainer: AppColors.surfaceSoft,
          surfaceContainerHigh: AppColors.surfaceSoft,
          surfaceContainerHighest: AppColors.surfaceCard,
          outline: AppColors.mutedSoft,
          outlineVariant: AppColors.hairline,
          inverseSurface: AppColors.ink,
          onInverseSurface: AppColors.onPrimary,
          inversePrimary: AppColors.brandAccent,
          shadow: const Color(0xFF000000),
          scrim: const Color(0xFF000000),
          surfaceTint: Colors.transparent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        // Back and close buttons that Flutter adds on its own use the app's
        // icon set too, not the stock Material arrows.
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (_) => const Icon(AppIcons.chevronBack, size: 18),
          closeButtonIconBuilder: (_) => const Icon(AppIcons.close, size: 20),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: ThemeController.overlayStyle,
          centerTitle: false,
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // rounded.lg
            side: BorderSide(color: AppColors.hairline, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.canvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // rounded.md
            borderSide: BorderSide(color: AppColors.hairline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.hairline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.ink, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
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
            shape: const StadiumBorder(),
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
            side: BorderSide(color: AppColors.hairline, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: const StadiumBorder(),
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
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.canvas,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedSoft,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: DividerThemeData(
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
            side: BorderSide(color: AppColors.hairline, width: 1),
          ),
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w500,
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
          shadowColor: const Color.fromRGBO(60, 45, 20, 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.hairline, width: 1),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          modalBarrierColor: Color.fromRGBO(0, 0, 0, 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          showDragHandle: false,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          shadowColor: const Color.fromRGBO(60, 45, 20, 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.hairline, width: 1),
          ),
          // Paper header with a serif date, like the rest of the app.
          headerBackgroundColor: AppColors.canvas,
          headerForegroundColor: AppColors.ink,
          headerHeadlineStyle: serif(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.ink),
          headerHelpStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: AppColors.mutedSoft,
          ),
          dividerColor: AppColors.hairline,
          dayForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : states.contains(WidgetState.disabled)
                ? AppColors.mutedSoft
                : AppColors.ink,
          ),
          dayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
          ),
          yearForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.ink,
          ),
          yearBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
          ),
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.muted),
          confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.ink),
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
          todayForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : AppColors.primary,
          ),
          todayBorder: BorderSide(color: AppColors.primary, width: 1.5),
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
            side: BorderSide(color: AppColors.hairline, width: 1),
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
          // Inverted paper: ink on light, paper on dark.
          backgroundColor: AppColors.ink,
          contentTextStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.onPrimary,
          ),
          actionTextColor: AppColors.isDark ? const Color(0xFF2B4C7E) : const Color(0xFFF2C46B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 44),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink,
            shape: const StadiumBorder(),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: AppColors.ink),
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.ink,
          selectionColor: AppColors.brandAccent.withValues(alpha: 0.28),
          selectionHandleColor: AppColors.ink,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.ink,
          linearTrackColor: AppColors.hairline,
          circularTrackColor: Colors.transparent,
          refreshBackgroundColor: AppColors.canvas,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.muted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceCard,
          ),
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.mutedSoft,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
          ),
          checkColor: WidgetStatePropertyAll(AppColors.onPrimary),
          side: BorderSide(color: AppColors.mutedSoft, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.mutedSoft,
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.hairline,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.08),
          valueIndicatorColor: AppColors.ink,
          valueIndicatorTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.ink,
          dividerColor: AppColors.hairline,
          labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: AppColors.ink,
          textColor: AppColors.ink,
          titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
          subtitleTextStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
        ),
        expansionTileTheme: ExpansionTileThemeData(
          iconColor: AppColors.ink,
          collapsedIconColor: AppColors.muted,
          textColor: AppColors.ink,
          collapsedTextColor: AppColors.ink,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onPrimary),
        ),
        menuTheme: MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.canvas),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            side: WidgetStatePropertyAll(BorderSide(color: AppColors.hairline)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: GoogleFonts.inter(fontSize: 14.5, color: AppColors.ink),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.canvas),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.canvas,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.ink,
            ),
            side: WidgetStatePropertyAll(BorderSide(color: AppColors.hairline)),
          ),
        ),
        badgeTheme: BadgeThemeData(backgroundColor: AppColors.error, textColor: AppColors.onPrimary),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.canvas,
          selectedColor: AppColors.primary,
          secondarySelectedColor: AppColors.primary,
          checkmarkColor: AppColors.onPrimary,
          secondaryLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
          // Ink text on paper, paper text once selected (the chip turns ink).
          labelStyle: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.ink,
            ),
          ),
          side: WidgetStateBorderSide.resolveWith(
            (s) => BorderSide(color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.hairline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: const StadiumBorder(),
        ),
      );
}

