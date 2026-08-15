import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';

enum PdfThemeId {
  classicBlue,
  modernMinimal,
  emeraldExecutive,
  slateElegance,
  warmCorporate,
  nordicFrame,
  leftRibbon,
  geometricBlock,
  securityGrid,
  splitTwoTone,
}

enum PdfPaperStyle {
  standard,
  minimalDividers,
  topAccentLine,
  doubleRule,
  warmParchment,
  architecturalFrame,
  leftVerticalRibbon,
  fullWidthBanner,
  securityDotGrid,
  asymmetricSplitHeader,
}

extension PdfThemeIdExtension on PdfThemeId {
  String get value {
    switch (this) {
      case PdfThemeId.classicBlue:
        return 'classic_blue';
      case PdfThemeId.modernMinimal:
        return 'modern_minimal';
      case PdfThemeId.emeraldExecutive:
        return 'emerald_executive';
      case PdfThemeId.slateElegance:
        return 'slate_elegance';
      case PdfThemeId.warmCorporate:
        return 'warm_corporate';
      case PdfThemeId.nordicFrame:
        return 'nordic_frame';
      case PdfThemeId.leftRibbon:
        return 'left_ribbon';
      case PdfThemeId.geometricBlock:
        return 'geometric_block';
      case PdfThemeId.securityGrid:
        return 'security_grid';
      case PdfThemeId.splitTwoTone:
        return 'split_two_tone';
    }
  }

  static PdfThemeId fromString(String? val) {
    switch (val) {
      case 'modern_minimal':
      case 'modern':
        return PdfThemeId.modernMinimal;
      case 'emerald_executive':
      case 'emerald':
        return PdfThemeId.emeraldExecutive;
      case 'slate_elegance':
      case 'slate':
        return PdfThemeId.slateElegance;
      case 'warm_corporate':
      case 'warm':
      case 'navy_bronze':
        return PdfThemeId.warmCorporate;
      case 'nordic_frame':
      case 'nordic':
        return PdfThemeId.nordicFrame;
      case 'left_ribbon':
      case 'ribbon':
        return PdfThemeId.leftRibbon;
      case 'geometric_block':
      case 'geometric':
        return PdfThemeId.geometricBlock;
      case 'security_grid':
      case 'security':
        return PdfThemeId.securityGrid;
      case 'split_two_tone':
      case 'two_tone':
        return PdfThemeId.splitTwoTone;
      case 'classic_blue':
      case 'classic':
      default:
        return PdfThemeId.classicBlue;
    }
  }
}

class PdfTheme {
  final PdfThemeId id;
  final String name;
  final String description;
  final String paperDesignName;
  final PdfPaperStyle paperStyle;
  final Color previewPrimary;
  final Color previewSecondary;
  final Color previewAccent;
  final Color previewBg;

  // PDF Colors
  final PdfColor primaryColor;
  final PdfColor secondaryColor;
  final PdfColor darkColor;
  final PdfColor slateColor;
  final PdfColor lightGray;
  final PdfColor borderColor;
  final PdfColor tableHeaderBg;
  final PdfColor tableHeaderTextColor;
  final PdfColor accentColor;

  const PdfTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.paperDesignName,
    required this.paperStyle,
    required this.previewPrimary,
    required this.previewSecondary,
    required this.previewAccent,
    required this.previewBg,
    required this.primaryColor,
    required this.secondaryColor,
    required this.darkColor,
    required this.slateColor,
    required this.lightGray,
    required this.borderColor,
    required this.tableHeaderBg,
    required this.tableHeaderTextColor,
    required this.accentColor,
  });

  // 1. Classic Blue
  static const PdfTheme classicBlue = PdfTheme(
    id: PdfThemeId.classicBlue,
    name: 'Classic Corporate',
    description: 'Balanced card containers with royal blue accents & dark slate headers',
    paperDesignName: 'Structured Card Canvas',
    paperStyle: PdfPaperStyle.standard,
    previewPrimary: Color(0xFF2563EB),
    previewSecondary: Color(0xFF1E293B),
    previewAccent: Color(0xFF10B981),
    previewBg: Color(0xFFF1F5F9),
    primaryColor: PdfColor(0.145, 0.388, 0.922), // #2563EB
    secondaryColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(0.945, 0.961, 0.976), // #F1F5F9
    borderColor: PdfColor(0.886, 0.910, 0.941), // #E2E8F0
    tableHeaderBg: PdfColor(0.118, 0.161, 0.231), // #1E293B
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.063, 0.725, 0.506), // #10B981
  );

  // 2. Modern Minimal
  static const PdfTheme modernMinimal = PdfTheme(
    id: PdfThemeId.modernMinimal,
    name: 'Modern Minimal',
    description: 'Swiss typography-first design with horizontal micro-rules and spacious layout',
    paperDesignName: 'Swiss Minimalist Sheet',
    paperStyle: PdfPaperStyle.minimalDividers,
    previewPrimary: Color(0xFF18181B),
    previewSecondary: Color(0xFF71717A),
    previewAccent: Color(0xFF27272A),
    previewBg: Color(0xFFFAFAFA),
    primaryColor: PdfColor(0.094, 0.094, 0.106), // #18181B
    secondaryColor: PdfColor(0.247, 0.247, 0.275), // #3F3F46
    darkColor: PdfColor(0.035, 0.035, 0.043), // #09090B
    slateColor: PdfColor(0.443, 0.443, 0.478), // #71717A
    lightGray: PdfColor(0.980, 0.980, 0.980), // #FAFAFA
    borderColor: PdfColor(0.894, 0.894, 0.906), // #E4E4E7
    tableHeaderBg: PdfColor(0.961, 0.961, 0.965), // #F4F4F5
    tableHeaderTextColor: PdfColor(0.094, 0.094, 0.106), // #18181B
    accentColor: PdfColor(0.153, 0.153, 0.165), // #27272A
  );

  // 3. Emerald Executive
  static const PdfTheme emeraldExecutive = PdfTheme(
    id: PdfThemeId.emeraldExecutive,
    name: 'Emerald Executive',
    description: 'Executive top color band with soft mint recipient panel and seal badge',
    paperDesignName: 'Executive Header Band',
    paperStyle: PdfPaperStyle.topAccentLine,
    previewPrimary: Color(0xFF065F46),
    previewSecondary: Color(0xFF047857),
    previewAccent: Color(0xFF10B981),
    previewBg: Color(0xFFF0FDF4),
    primaryColor: PdfColor(0.024, 0.373, 0.275), // #065F46
    secondaryColor: PdfColor(0.016, 0.471, 0.341), // #047857
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.278, 0.333, 0.412), // #475569
    lightGray: PdfColor(0.941, 0.992, 0.957), // #F0FDF4
    borderColor: PdfColor(0.820, 0.980, 0.898), // #D1FAE5
    tableHeaderBg: PdfColor(0.024, 0.373, 0.275), // #065F46
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.063, 0.725, 0.506), // #10B981
  );

  // 4. Slate Elegance
  static const PdfTheme slateElegance = PdfTheme(
    id: PdfThemeId.slateElegance,
    name: 'Slate Elegance',
    description: 'Symmetrical double-rule dividers with graphite headers & cool slate container',
    paperDesignName: 'Symmetrical Double-Rule',
    paperStyle: PdfPaperStyle.doubleRule,
    previewPrimary: Color(0xFF334155),
    previewSecondary: Color(0xFF64748B),
    previewAccent: Color(0xFF0EA5E9),
    previewBg: Color(0xFFF8FAFC),
    primaryColor: PdfColor(0.200, 0.255, 0.333), // #334155
    secondaryColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(0.973, 0.980, 0.988), // #F8FAFC
    borderColor: PdfColor(0.886, 0.910, 0.941), // #E2E8F0
    tableHeaderBg: PdfColor(0.200, 0.255, 0.333), // #334155
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.055, 0.647, 0.914), // #0EA5E9
  );

  // 5. Warm Corporate
  static const PdfTheme warmCorporate = PdfTheme(
    id: PdfThemeId.warmCorporate,
    name: 'Warm Corporate',
    description: 'Warm parchment paper tint with navy blue block headers & bronze accent lines',
    paperDesignName: 'Warm Parchment Sheet',
    paperStyle: PdfPaperStyle.warmParchment,
    previewPrimary: Color(0xFF1E3A8A),
    previewSecondary: Color(0xFFB45309),
    previewAccent: Color(0xFFD97706),
    previewBg: Color(0xFFFFFBEB),
    primaryColor: PdfColor(0.118, 0.227, 0.541), // #1E3A8A
    secondaryColor: PdfColor(0.706, 0.325, 0.035), // #B45309
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(1.000, 0.984, 0.922), // #FFFBEB
    borderColor: PdfColor(0.992, 0.953, 0.780), // #FEF3C7
    tableHeaderBg: PdfColor(0.118, 0.227, 0.541), // #1E3A8A
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.706, 0.325, 0.035), // #B45309
  );

  // 6. Nordic Frame (New)
  static const PdfTheme nordicFrame = PdfTheme(
    id: PdfThemeId.nordicFrame,
    name: 'Nordic Frame',
    description: 'Architectural double-line border frame with clean corner geometry',
    paperDesignName: 'Architectural Border Frame',
    paperStyle: PdfPaperStyle.architecturalFrame,
    previewPrimary: Color(0xFF0F766E),
    previewSecondary: Color(0xFF115E59),
    previewAccent: Color(0xFF14B8A6),
    previewBg: Color(0xFFF0FDFA),
    primaryColor: PdfColor(0.059, 0.463, 0.431), // #0F766E
    secondaryColor: PdfColor(0.067, 0.369, 0.349), // #115E59
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.278, 0.333, 0.412), // #475569
    lightGray: PdfColor(0.941, 0.992, 0.980), // #F0FDFA
    borderColor: PdfColor(0.800, 0.957, 0.941), // #CCFBF1
    tableHeaderBg: PdfColor(0.059, 0.463, 0.431), // #0F766E
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.078, 0.722, 0.651), // #14B8A6
  );

  // 7. Left Accent Ribbon (New)
  static const PdfTheme leftRibbon = PdfTheme(
    id: PdfThemeId.leftRibbon,
    name: 'Left Accent Ribbon',
    description: 'Solid vertical accent ribbon down left margin with connected header block',
    paperDesignName: 'Vertical Margin Ribbon',
    paperStyle: PdfPaperStyle.leftVerticalRibbon,
    previewPrimary: Color(0xFF4338CA),
    previewSecondary: Color(0xFF3730A3),
    previewAccent: Color(0xFF6366F1),
    previewBg: Color(0xFFEEF2FF),
    primaryColor: PdfColor(0.263, 0.220, 0.792), // #4338CA
    secondaryColor: PdfColor(0.216, 0.188, 0.639), // #3730A3
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(0.933, 0.949, 1.000), // #EEF2FF
    borderColor: PdfColor(0.878, 0.906, 0.980), // #E0E7FF
    tableHeaderBg: PdfColor(0.263, 0.220, 0.792), // #4338CA
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.388, 0.400, 0.945), // #6366F1
  );

  // 8. Geometric Banner (New)
  static const PdfTheme geometricBlock = PdfTheme(
    id: PdfThemeId.geometricBlock,
    name: 'Geometric Banner',
    description: 'Full-width solid dark header banner with inverted typography & dark total block',
    paperDesignName: 'Full-Width Dark Banner',
    paperStyle: PdfPaperStyle.fullWidthBanner,
    previewPrimary: Color(0xFF1E293B),
    previewSecondary: Color(0xFF3B82F6),
    previewAccent: Color(0xFF60A5FA),
    previewBg: Color(0xFFF8FAFC),
    primaryColor: PdfColor(0.118, 0.161, 0.231), // #1E293B
    secondaryColor: PdfColor(0.231, 0.510, 0.965), // #3B82F6
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(0.973, 0.980, 0.988), // #F8FAFC
    borderColor: PdfColor(0.886, 0.910, 0.941), // #E2E8F0
    tableHeaderBg: PdfColor(0.118, 0.161, 0.231), // #1E293B
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.231, 0.510, 0.965), // #3B82F6
  );

  // 9. Security Guilloche Grid (New)
  static const PdfTheme securityGrid = PdfTheme(
    id: PdfThemeId.securityGrid,
    name: 'Security Grid',
    description: 'Formal document security micro-dot watermark grid with certificate styling',
    paperDesignName: 'Security Micro-Dot Grid',
    paperStyle: PdfPaperStyle.securityDotGrid,
    previewPrimary: Color(0xFF1E40AF),
    previewSecondary: Color(0xFF1D4ED8),
    previewAccent: Color(0xFF3B82F6),
    previewBg: Color(0xFFEFF6FF),
    primaryColor: PdfColor(0.118, 0.251, 0.686), // #1E40AF
    secondaryColor: PdfColor(0.114, 0.306, 0.847), // #1D4ED8
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.278, 0.333, 0.412), // #475569
    lightGray: PdfColor(0.937, 0.965, 1.000), // #EFF6FF
    borderColor: PdfColor(0.749, 0.859, 0.988), // #BFDBFE
    tableHeaderBg: PdfColor(0.118, 0.251, 0.686), // #1E40AF
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.231, 0.510, 0.965), // #3B82F6
  );

  // 10. Two-Tone Split (New)
  static const PdfTheme splitTwoTone = PdfTheme(
    id: PdfThemeId.splitTwoTone,
    name: 'Two-Tone Split',
    description: 'Asymmetric split header with dark slate branding and light metadata box',
    paperDesignName: 'Two-Tone Split Header',
    paperStyle: PdfPaperStyle.asymmetricSplitHeader,
    previewPrimary: Color(0xFF374151),
    previewSecondary: Color(0xFF0284C7),
    previewAccent: Color(0xFF38BDF8),
    previewBg: Color(0xFFF0F9FF),
    primaryColor: PdfColor(0.216, 0.255, 0.318), // #374151
    secondaryColor: PdfColor(0.008, 0.518, 0.780), // #0284C7
    darkColor: PdfColor(0.059, 0.090, 0.165), // #0F172A
    slateColor: PdfColor(0.392, 0.455, 0.545), // #64748B
    lightGray: PdfColor(0.941, 0.976, 1.000), // #F0F9FF
    borderColor: PdfColor(0.878, 0.906, 0.941), // #E0E7F0
    tableHeaderBg: PdfColor(0.216, 0.255, 0.318), // #374151
    tableHeaderTextColor: PdfColors.white,
    accentColor: PdfColor(0.008, 0.518, 0.780), // #0284C7
  );

  static const List<PdfTheme> all = [
    classicBlue,
    modernMinimal,
    emeraldExecutive,
    slateElegance,
    warmCorporate,
    nordicFrame,
    leftRibbon,
    geometricBlock,
    securityGrid,
    splitTwoTone,
  ];

  static PdfTheme get defaultTheme => classicBlue;

  static PdfTheme fromId(String? id) {
    if (id == null) return defaultTheme;
    final themeId = PdfThemeIdExtension.fromString(id);
    return all.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => defaultTheme,
    );
  }
}
