import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';

enum PdfThemeCategory {
  professional('Professional'),
  simple('Simple'),
  bold('Bold'),
  creative('Creative'),
  retailGst('Retail & GST');

  const PdfThemeCategory(this.label);

  final String label;

  int get order => index;
}

enum PdfThemeId {
  classicBlue('classic_blue', PdfThemeCategory.professional),
  modernMinimal('modern_minimal', PdfThemeCategory.simple),
  emeraldExecutive('emerald_executive', PdfThemeCategory.professional),
  slateElegance('slate_elegance', PdfThemeCategory.simple),
  warmCorporate('warm_corporate', PdfThemeCategory.professional),
  nordicFrame('nordic_frame', PdfThemeCategory.simple),
  leftRibbon('left_ribbon', PdfThemeCategory.bold),
  geometricBlock('geometric_block', PdfThemeCategory.bold),
  securityGrid('security_grid', PdfThemeCategory.professional),
  splitTwoTone('split_two_tone', PdfThemeCategory.creative),
  charcoalLetterhead('charcoal_letterhead', PdfThemeCategory.professional),
  navyLetterhead('navy_letterhead', PdfThemeCategory.professional),
  forestSeal('forest_seal', PdfThemeCategory.professional),
  linenRule('linen_rule', PdfThemeCategory.simple),
  mistLine('mist_line', PdfThemeCategory.simple),
  oliveFrame('olive_frame', PdfThemeCategory.simple),
  crimsonSlash('crimson_slash', PdfThemeCategory.bold),
  indigoSlash('indigo_slash', PdfThemeCategory.bold),
  copperBanner('copper_banner', PdfThemeCategory.bold),
  tealWave('teal_wave', PdfThemeCategory.creative),
  orchidWave('orchid_wave', PdfThemeCategory.creative),
  clayRibbon('clay_ribbon', PdfThemeCategory.creative),
  mulberrySplit('mulberry_split', PdfThemeCategory.creative),
  saffronLedger('saffron_ledger', PdfThemeCategory.retailGst),
  peacockLedger('peacock_ledger', PdfThemeCategory.retailGst),
  graphiteReceipt('graphite_receipt', PdfThemeCategory.retailGst),
  roseReceipt('rose_receipt', PdfThemeCategory.retailGst),
  oxbloodSeal('oxblood_seal', PdfThemeCategory.retailGst);

  const PdfThemeId(this.value, this.category);

  final String value;
  final PdfThemeCategory category;
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
  cornerWave,
  diagonalBand,
  letterheadBar,
  stampBorder,
  gstLedger,
  receiptStrip,
}

extension PdfThemeIdExtension on PdfThemeId {
  static PdfThemeId fromString(String? val) {
    // Estimates once stored the Dart enum name (e.g. "emeraldExecutive").
    for (final id in PdfThemeId.values) {
      if (id.value == val || id.name == val) return id;
    }
    switch (val) {
      case 'modern':
        return PdfThemeId.modernMinimal;
      case 'emerald':
        return PdfThemeId.emeraldExecutive;
      case 'slate':
        return PdfThemeId.slateElegance;
      case 'warm':
      case 'navy_bronze':
        return PdfThemeId.warmCorporate;
      case 'nordic':
        return PdfThemeId.nordicFrame;
      case 'ribbon':
        return PdfThemeId.leftRibbon;
      case 'geometric':
        return PdfThemeId.geometricBlock;
      case 'security':
        return PdfThemeId.securityGrid;
      case 'two_tone':
        return PdfThemeId.splitTwoTone;
      case 'classic':
      default:
        return PdfThemeId.classicBlue;
    }
  }
}

class PdfTheme {
  final PdfThemeId id;
  PdfThemeCategory get category => id.category;

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

  factory PdfTheme._palette({
    required PdfThemeId id,
    required String name,
    required String description,
    required String paperDesignName,
    required PdfPaperStyle paperStyle,
    required int primary,
    required int secondary,
    required int accent,
    required int background,
    required int border,
    bool lightTableHeader = false,
  }) {
    const ink = PdfColor.fromInt(0xFF21242A);
    return PdfTheme(
      id: id,
      name: name,
      description: description,
      paperDesignName: paperDesignName,
      paperStyle: paperStyle,
      previewPrimary: Color(primary),
      previewSecondary: Color(secondary),
      previewAccent: Color(accent),
      previewBg: Color(background),
      primaryColor: PdfColor.fromInt(primary),
      secondaryColor: PdfColor.fromInt(secondary),
      darkColor: ink,
      slateColor: const PdfColor.fromInt(0xFF515762),
      lightGray: PdfColor.fromInt(background),
      borderColor: PdfColor.fromInt(border),
      tableHeaderBg: PdfColor.fromInt(lightTableHeader ? background : primary),
      tableHeaderTextColor: lightTableHeader ? ink : PdfColors.white,
      accentColor: PdfColor.fromInt(accent),
    );
  }

  // 1. Classic Blue
  static const PdfTheme classicBlue = PdfTheme(
    id: PdfThemeId.classicBlue,
    name: 'Classic Corporate',
    description: 'Clean ruled layout with a royal blue title and total',
    paperDesignName: 'Classic Ruled Sheet',
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
    description: 'Black and white, type first, with fine rules and generous space',
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
    description: 'A band of colour across the head of the sheet, with matching title and total',
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
    description: 'Thick-and-thin double rules at head and foot, in graphite',
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
    description: 'Warm parchment tint with a navy title and a bronze head rule',
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
    description: 'A fine double-line frame around the whole sheet',
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
    description: 'A solid ribbon of colour down the left edge, with a filled table header',
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
    description: 'Edge-to-edge dark banner with white type and a filled table header',
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
    description: 'A faint dot grid behind the text, like security paper',
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
    description: 'Slate and sky palette with a filled table header',
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

  static final all = List<PdfTheme>.unmodifiable([
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
    PdfTheme._palette(
      id: PdfThemeId.charcoalLetterhead,
      name: 'Charcoal Letterhead',
      description: 'Charcoal bars with a brass accent',
      paperDesignName: 'Letterhead Bars',
      paperStyle: PdfPaperStyle.letterheadBar,
      primary: 0xFF30343A,
      secondary: 0xFF676B73,
      accent: 0xFFC8A46C,
      background: 0xFFF4F1EC,
      border: 0xFFD6D1C9,
    ),
    PdfTheme._palette(
      id: PdfThemeId.navyLetterhead,
      name: 'Navy Letterhead',
      description: 'A midnight blue letterhead with a cool blue footer',
      paperDesignName: 'Letterhead Bars',
      paperStyle: PdfPaperStyle.letterheadBar,
      primary: 0xFF142D46,
      secondary: 0xFF416988,
      accent: 0xFF87B6DC,
      background: 0xFFEEF5FB,
      border: 0xFFC8D9E7,
    ),
    PdfTheme._palette(
      id: PdfThemeId.forestSeal,
      name: 'Forest Seal',
      description: 'An evergreen double frame with corner marks',
      paperDesignName: 'Stamped Double Border',
      paperStyle: PdfPaperStyle.stampBorder,
      primary: 0xFF234C37,
      secondary: 0xFF486850,
      accent: 0xFF88A26C,
      background: 0xFFEEF5ED,
      border: 0xFFCAD9C9,
    ),
    PdfTheme._palette(
      id: PdfThemeId.linenRule,
      name: 'Linen Rule',
      description: 'A cocoa title and fine rules on warm white',
      paperDesignName: 'Minimal Rules',
      paperStyle: PdfPaperStyle.minimalDividers,
      primary: 0xFF5E4333,
      secondary: 0xFF705B4E,
      accent: 0xFFA9896F,
      background: 0xFFFAF3E9,
      border: 0xFFE7D8C9,
      lightTableHeader: true,
    ),
    PdfTheme._palette(
      id: PdfThemeId.mistLine,
      name: 'Mist Line',
      description: 'A slender blue-grey rule and a quiet, cool palette',
      paperDesignName: 'Top Accent Line',
      paperStyle: PdfPaperStyle.topAccentLine,
      primary: 0xFF45647B,
      secondary: 0xFF627889,
      accent: 0xFF95B4C9,
      background: 0xFFEEF5F8,
      border: 0xFFCEDDE6,
    ),
    PdfTheme._palette(
      id: PdfThemeId.oliveFrame,
      name: 'Olive Frame',
      description: 'A slim olive frame with a pale sage palette',
      paperDesignName: 'Architectural Border Frame',
      paperStyle: PdfPaperStyle.architecturalFrame,
      primary: 0xFF4B5526,
      secondary: 0xFF646B42,
      accent: 0xFFA5AD74,
      background: 0xFFF2F4E8,
      border: 0xFFD8DFC4,
    ),
    PdfTheme._palette(
      id: PdfThemeId.crimsonSlash,
      name: 'Crimson Slash',
      description: 'An angled burgundy band with a coral edge',
      paperDesignName: 'Diagonal Header Band',
      paperStyle: PdfPaperStyle.diagonalBand,
      primary: 0xFF801C39,
      secondary: 0xFF9E3355,
      accent: 0xFFF39992,
      background: 0xFFFCEEF1,
      border: 0xFFEBC6D0,
    ),
    PdfTheme._palette(
      id: PdfThemeId.indigoSlash,
      name: 'Indigo Slash',
      description: 'An indigo slash edged in periwinkle',
      paperDesignName: 'Diagonal Header Band',
      paperStyle: PdfPaperStyle.diagonalBand,
      primary: 0xFF38286E,
      secondary: 0xFF51409B,
      accent: 0xFFAFA0F1,
      background: 0xFFF1EDFC,
      border: 0xFFD9D0F2,
    ),
    PdfTheme._palette(
      id: PdfThemeId.copperBanner,
      name: 'Copper Banner',
      description: 'A burnt copper banner with a sand accent',
      paperDesignName: 'Full-Width Banner',
      paperStyle: PdfPaperStyle.fullWidthBanner,
      primary: 0xFF78371E,
      secondary: 0xFF924C2B,
      accent: 0xFFE6AA80,
      background: 0xFFFBF0E8,
      border: 0xFFE8CFBD,
    ),
    PdfTheme._palette(
      id: PdfThemeId.tealWave,
      name: 'Teal Wave',
      description: 'Sweeping sea-glass curves in the top corner',
      paperDesignName: 'Corner Wave',
      paperStyle: PdfPaperStyle.cornerWave,
      primary: 0xFF116460,
      secondary: 0xFF25817B,
      accent: 0xFF68C7B8,
      background: 0xFFE9F8F5,
      border: 0xFFC0E5DE,
    ),
    PdfTheme._palette(
      id: PdfThemeId.orchidWave,
      name: 'Orchid Wave',
      description: 'Lilac curves over a soft violet corner',
      paperDesignName: 'Corner Wave',
      paperStyle: PdfPaperStyle.cornerWave,
      primary: 0xFF783D83,
      secondary: 0xFF935198,
      accent: 0xFFD4A5DB,
      background: 0xFFF9EDF9,
      border: 0xFFE9CDEB,
    ),
    PdfTheme._palette(
      id: PdfThemeId.clayRibbon,
      name: 'Clay Ribbon',
      description: 'A terracotta spine with peach accents',
      paperDesignName: 'Vertical Margin Ribbon',
      paperStyle: PdfPaperStyle.leftVerticalRibbon,
      primary: 0xFF9B472C,
      secondary: 0xFF83422D,
      accent: 0xFFEEAF88,
      background: 0xFFFBEEE6,
      border: 0xFFEDD2C3,
    ),
    PdfTheme._palette(
      id: PdfThemeId.mulberrySplit,
      name: 'Mulberry Split',
      description: 'Mulberry and blush in a two-panel heading',
      paperDesignName: 'Two-Tone Split Header',
      paperStyle: PdfPaperStyle.asymmetricSplitHeader,
      primary: 0xFF582640,
      secondary: 0xFF784661,
      accent: 0xFFC68CA7,
      background: 0xFFF8EAF1,
      border: 0xFFE8CEDD,
    ),
    PdfTheme._palette(
      id: PdfThemeId.saffronLedger,
      name: 'Saffron Ledger',
      description: 'A saffron heading and a fully ruled tax ledger',
      paperDesignName: 'GST Ledger',
      paperStyle: PdfPaperStyle.gstLedger,
      primary: 0xFF854800,
      secondary: 0xFFA75C15,
      accent: 0xFFE6A948,
      background: 0xFFFFF4DE,
      border: 0xFFE8D2AD,
      lightTableHeader: true,
    ),
    PdfTheme._palette(
      id: PdfThemeId.peacockLedger,
      name: 'Peacock Ledger',
      description: 'Deep petrol blue with a boxed heading and item grid',
      paperDesignName: 'GST Ledger',
      paperStyle: PdfPaperStyle.gstLedger,
      primary: 0xFF005362,
      secondary: 0xFF167184,
      accent: 0xFF69B9C5,
      background: 0xFFE7F6F7,
      border: 0xFFBDDDE1,
      lightTableHeader: true,
    ),
    PdfTheme._palette(
      id: PdfThemeId.graphiteReceipt,
      name: 'Graphite Receipt',
      description: 'A centred monochrome receipt with dashed rules',
      paperDesignName: 'Receipt Strip',
      paperStyle: PdfPaperStyle.receiptStrip,
      primary: 0xFF303534,
      secondary: 0xFF5A625E,
      accent: 0xFF9EA8A1,
      background: 0xFFF1F4F1,
      border: 0xFFD4DDD5,
      lightTableHeader: true,
    ),
    PdfTheme._palette(
      id: PdfThemeId.roseReceipt,
      name: 'Rose Receipt',
      description: 'Dusty rose paper edges around a narrow receipt column',
      paperDesignName: 'Receipt Strip',
      paperStyle: PdfPaperStyle.receiptStrip,
      primary: 0xFF884451,
      secondary: 0xFFA2636D,
      accent: 0xFFD9A3AA,
      background: 0xFFFBEEF0,
      border: 0xFFEBD1D6,
      lightTableHeader: true,
    ),
    PdfTheme._palette(
      id: PdfThemeId.oxbloodSeal,
      name: 'Oxblood Seal',
      description: 'An oxblood double border with gold corner marks',
      paperDesignName: 'Stamped Double Border',
      paperStyle: PdfPaperStyle.stampBorder,
      primary: 0xFF662629,
      secondary: 0xFF844649,
      accent: 0xFFB78B57,
      background: 0xFFFAEFE9,
      border: 0xFFE8D2C8,
    ),
  ]);

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
