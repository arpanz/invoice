import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';

enum PdfThemeId {
  classicBlue,
  modernMinimal,
  emeraldExecutive,
  slateElegance,
  warmCorporate,
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

  static const PdfTheme classicBlue = PdfTheme(
    id: PdfThemeId.classicBlue,
    name: 'Classic Blue',
    description: 'Traditional corporate layout with balanced royal blue accents',
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

  static const PdfTheme modernMinimal = PdfTheme(
    id: PdfThemeId.modernMinimal,
    name: 'Modern Minimal',
    description: 'Clean Swiss typography style with light dividers and crisp obsidian',
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
    tableHeaderBg: PdfColor(0.961, 0.961, 0.965), // #F4F4F5 (Minimalist light header)
    tableHeaderTextColor: PdfColor(0.094, 0.094, 0.106), // #18181B
    accentColor: PdfColor(0.153, 0.153, 0.165), // #27272A
  );

  static const PdfTheme emeraldExecutive = PdfTheme(
    id: PdfThemeId.emeraldExecutive,
    name: 'Emerald Executive',
    description: 'Executive forest green styling with soft sage accents',
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

  static const PdfTheme slateElegance = PdfTheme(
    id: PdfThemeId.slateElegance,
    name: 'Slate Elegance',
    description: 'Modern graphite and steel gray aesthetic with clean lines',
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

  static const PdfTheme warmCorporate = PdfTheme(
    id: PdfThemeId.warmCorporate,
    name: 'Warm Corporate',
    description: 'Prestigious deep navy headers with warm bronze accents',
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

  static const List<PdfTheme> all = [
    classicBlue,
    modernMinimal,
    emeraldExecutive,
    slateElegance,
    warmCorporate,
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
