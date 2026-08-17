import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'pdf_theme.dart';

/// Available font family pairings for invoice typography.
enum InvoiceFontFamily {
  cleanSans,
  editorialSerif,
  geometricSans,
  modernMono,
}

extension InvoiceFontFamilyExtension on InvoiceFontFamily {
  String get key {
    switch (this) {
      case InvoiceFontFamily.cleanSans:
        return 'clean_sans';
      case InvoiceFontFamily.editorialSerif:
        return 'editorial_serif';
      case InvoiceFontFamily.geometricSans:
        return 'geometric_sans';
      case InvoiceFontFamily.modernMono:
        return 'modern_mono';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceFontFamily.cleanSans:
        return 'Clean Sans';
      case InvoiceFontFamily.editorialSerif:
        return 'Editorial Serif';
      case InvoiceFontFamily.geometricSans:
        return 'Geometric';
      case InvoiceFontFamily.modernMono:
        return 'Tech Mono';
    }
  }

  String get description {
    switch (this) {
      case InvoiceFontFamily.cleanSans:
        return 'Modern, clear & highly legible (Inter / Noto)';
      case InvoiceFontFamily.editorialSerif:
        return 'Formal, premium & classic (Lora / Merriweather)';
      case InvoiceFontFamily.geometricSans:
        return 'Sharp, sleek & contemporary (Montserrat / Poppins)';
      case InvoiceFontFamily.modernMono:
        return 'Technical, precise & balanced (Space Mono)';
    }
  }

  static InvoiceFontFamily fromKey(String? val) {
    switch (val) {
      case 'editorial_serif':
      case 'serif':
        return InvoiceFontFamily.editorialSerif;
      case 'geometric_sans':
      case 'geometric':
        return InvoiceFontFamily.geometricSans;
      case 'modern_mono':
      case 'mono':
        return InvoiceFontFamily.modernMono;
      case 'clean_sans':
      case 'sans':
      default:
        return InvoiceFontFamily.cleanSans;
    }
  }
}

/// Sizing and document density.
enum InvoiceDensity {
  compact,
  regular,
  spacious,
}

extension InvoiceDensityExtension on InvoiceDensity {
  String get key {
    switch (this) {
      case InvoiceDensity.compact:
        return 'compact';
      case InvoiceDensity.regular:
        return 'regular';
      case InvoiceDensity.spacious:
        return 'spacious';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceDensity.compact:
        return 'Compact';
      case InvoiceDensity.regular:
        return 'Regular';
      case InvoiceDensity.spacious:
        return 'Spacious';
    }
  }

  String get description {
    switch (this) {
      case InvoiceDensity.compact:
        return '85% scale · Fits multi-item invoices onto a single page';
      case InvoiceDensity.regular:
        return '100% scale · Standard balanced corporate layout';
      case InvoiceDensity.spacious:
        return '115% scale · High readability for service or single-item invoices';
    }
  }

  double get scaleFactor {
    switch (this) {
      case InvoiceDensity.compact:
        return 0.86;
      case InvoiceDensity.regular:
        return 1.0;
      case InvoiceDensity.spacious:
        return 1.14;
    }
  }

  static InvoiceDensity fromKey(String? val) {
    switch (val) {
      case 'compact':
        return InvoiceDensity.compact;
      case 'spacious':
        return InvoiceDensity.spacious;
      case 'regular':
      default:
        return InvoiceDensity.regular;
    }
  }
}

/// Header element positioning and alignment.
enum HeaderPosition {
  logoLeftDetailsRight,
  logoRightDetailsLeft,
  centeredLogo,
  fullWidthBanner,
}

extension HeaderPositionExtension on HeaderPosition {
  String get key {
    switch (this) {
      case HeaderPosition.logoLeftDetailsRight:
        return 'logo_left';
      case HeaderPosition.logoRightDetailsLeft:
        return 'logo_right';
      case HeaderPosition.centeredLogo:
        return 'centered';
      case HeaderPosition.fullWidthBanner:
        return 'full_banner';
    }
  }

  String get displayName {
    switch (this) {
      case HeaderPosition.logoLeftDetailsRight:
        return 'Left Logo';
      case HeaderPosition.logoRightDetailsLeft:
        return 'Right Logo';
      case HeaderPosition.centeredLogo:
        return 'Centered';
      case HeaderPosition.fullWidthBanner:
        return 'Banner';
    }
  }

  String get description {
    switch (this) {
      case HeaderPosition.logoLeftDetailsRight:
        return 'Business & logo on left, invoice details on right';
      case HeaderPosition.logoRightDetailsLeft:
        return 'Invoice title & meta on left, logo on right';
      case HeaderPosition.centeredLogo:
        return 'Centered branding with balanced metadata pills';
      case HeaderPosition.fullWidthBanner:
        return 'Full-width solid color accent header';
    }
  }

  static HeaderPosition fromKey(String? val) {
    switch (val) {
      case 'logo_right':
        return HeaderPosition.logoRightDetailsLeft;
      case 'centered':
        return HeaderPosition.centeredLogo;
      case 'full_banner':
        return HeaderPosition.fullWidthBanner;
      case 'logo_left':
      default:
        return HeaderPosition.logoLeftDetailsRight;
    }
  }
}

/// Address block arrangement.
enum AddressLayout {
  sideBySide,
  inverted,
  stacked,
}

extension AddressLayoutExtension on AddressLayout {
  String get key {
    switch (this) {
      case AddressLayout.sideBySide:
        return 'side_by_side';
      case AddressLayout.inverted:
        return 'inverted';
      case AddressLayout.stacked:
        return 'stacked';
    }
  }

  String get displayName {
    switch (this) {
      case AddressLayout.sideBySide:
        return 'Side by Side';
      case AddressLayout.inverted:
        return 'Inverted';
      case AddressLayout.stacked:
        return 'Stacked';
    }
  }

  String get description {
    switch (this) {
      case AddressLayout.sideBySide:
        return 'From (Business) on left · Bill To (Client) on right';
      case AddressLayout.inverted:
        return 'Bill To (Client) on left · From (Business) on right';
      case AddressLayout.stacked:
        return 'Full-width From card above Bill To card';
    }
  }

  static AddressLayout fromKey(String? val) {
    switch (val) {
      case 'inverted':
        return AddressLayout.inverted;
      case 'stacked':
        return AddressLayout.stacked;
      case 'side_by_side':
      default:
        return AddressLayout.sideBySide;
    }
  }
}

/// Curated Color Palette Preset for rapid customization.
class ColorPalettePreset {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;

  const ColorPalettePreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  static const List<ColorPalettePreset> presets = [
    ColorPalettePreset(
      name: 'Royal Blue',
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF1E293B),
      accent: Color(0xFF10B981),
    ),
    ColorPalettePreset(
      name: 'Emerald Forest',
      primary: Color(0xFF065F46),
      secondary: Color(0xFF047857),
      accent: Color(0xFF10B981),
    ),
    ColorPalettePreset(
      name: 'Slate Graphite',
      primary: Color(0xFF334155),
      secondary: Color(0xFF64748B),
      accent: Color(0xFF0EA5E9),
    ),
    ColorPalettePreset(
      name: 'Obsidian Black',
      primary: Color(0xFF18181B),
      secondary: Color(0xFF3F3F46),
      accent: Color(0xFF27272A),
    ),
    ColorPalettePreset(
      name: 'Warm Amber',
      primary: Color(0xFF1E3A8A),
      secondary: Color(0xFFB45309),
      accent: Color(0xFFD97706),
    ),
    ColorPalettePreset(
      name: 'Nordic Teal',
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF115E59),
      accent: Color(0xFF14B8A6),
    ),
    ColorPalettePreset(
      name: 'Indigo Violet',
      primary: Color(0xFF4338CA),
      secondary: Color(0xFF3730A3),
      accent: Color(0xFF6366F1),
    ),
    ColorPalettePreset(
      name: 'Crimson Executive',
      primary: Color(0xFF991B1B),
      secondary: Color(0xFF7F1D1D),
      accent: Color(0xFFEF4444),
    ),
  ];
}

/// The comprehensive invoice and estimate visual customization model.
class InvoiceCustomizationConfig {
  final PdfThemeId themeId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final InvoiceFontFamily fontFamily;
  final InvoiceDensity density;
  final HeaderPosition headerPosition;
  final AddressLayout addressLayout;

  // Visibility & Section Toggles
  final bool showBankDetails;
  final bool showUpiDetails;
  final bool showSignature;
  final bool showNotes;
  final bool showTaxColumn;
  final bool showUnitPrice;
  final bool showQuantity;
  final String? customFooterMessage;

  const InvoiceCustomizationConfig({
    this.themeId = PdfThemeId.classicBlue,
    this.primaryColor = const Color(0xFF2563EB),
    this.secondaryColor = const Color(0xFF1E293B),
    this.accentColor = const Color(0xFF10B981),
    this.fontFamily = InvoiceFontFamily.cleanSans,
    this.density = InvoiceDensity.regular,
    this.headerPosition = HeaderPosition.logoLeftDetailsRight,
    this.addressLayout = AddressLayout.sideBySide,
    this.showBankDetails = true,
    this.showUpiDetails = true,
    this.showSignature = true,
    this.showNotes = true,
    this.showTaxColumn = true,
    this.showUnitPrice = true,
    this.showQuantity = true,
    this.customFooterMessage,
  });

  /// Factory from existing base PdfTheme
  factory InvoiceCustomizationConfig.fromTheme(PdfTheme theme) {
    return InvoiceCustomizationConfig(
      themeId: theme.id,
      primaryColor: theme.previewPrimary,
      secondaryColor: theme.previewSecondary,
      accentColor: theme.previewAccent,
      headerPosition: theme.paperStyle == PdfPaperStyle.fullWidthBanner
          ? HeaderPosition.fullWidthBanner
          : (theme.paperStyle == PdfPaperStyle.asymmetricSplitHeader
              ? HeaderPosition.logoRightDetailsLeft
              : HeaderPosition.logoLeftDetailsRight),
      addressLayout: AddressLayout.sideBySide,
    );
  }

  InvoiceCustomizationConfig copyWith({
    PdfThemeId? themeId,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    InvoiceFontFamily? fontFamily,
    InvoiceDensity? density,
    HeaderPosition? headerPosition,
    AddressLayout? addressLayout,
    bool? showBankDetails,
    bool? showUpiDetails,
    bool? showSignature,
    bool? showNotes,
    bool? showTaxColumn,
    bool? showUnitPrice,
    bool? showQuantity,
    String? customFooterMessage,
  }) {
    return InvoiceCustomizationConfig(
      themeId: themeId ?? this.themeId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      density: density ?? this.density,
      headerPosition: headerPosition ?? this.headerPosition,
      addressLayout: addressLayout ?? this.addressLayout,
      showBankDetails: showBankDetails ?? this.showBankDetails,
      showUpiDetails: showUpiDetails ?? this.showUpiDetails,
      showSignature: showSignature ?? this.showSignature,
      showNotes: showNotes ?? this.showNotes,
      showTaxColumn: showTaxColumn ?? this.showTaxColumn,
      showUnitPrice: showUnitPrice ?? this.showUnitPrice,
      showQuantity: showQuantity ?? this.showQuantity,
      customFooterMessage: customFooterMessage ?? this.customFooterMessage,
    );
  }

  /// Converts this configuration to an active PdfTheme with custom color overrides.
  PdfTheme toPdfTheme() {
    final baseTheme = PdfTheme.all.firstWhere(
      (t) => t.id == themeId,
      orElse: () => PdfTheme.defaultTheme,
    );

    // If colors match base, return baseTheme directly
    if (primaryColor.toARGB32() == baseTheme.previewPrimary.toARGB32() &&
        secondaryColor.toARGB32() == baseTheme.previewSecondary.toARGB32() &&
        accentColor.toARGB32() == baseTheme.previewAccent.toARGB32()) {
      return baseTheme;
    }

    final pPdf = PdfColor.fromInt(primaryColor.toARGB32());
    final sPdf = PdfColor.fromInt(secondaryColor.toARGB32());
    final aPdf = PdfColor.fromInt(accentColor.toARGB32());

    return PdfTheme(
      id: baseTheme.id,
      name: baseTheme.name,
      description: baseTheme.description,
      paperDesignName: baseTheme.paperDesignName,
      paperStyle: baseTheme.paperStyle,
      previewPrimary: primaryColor,
      previewSecondary: secondaryColor,
      previewAccent: accentColor,
      previewBg: baseTheme.previewBg,
      primaryColor: pPdf,
      secondaryColor: sPdf,
      darkColor: baseTheme.darkColor,
      slateColor: baseTheme.slateColor,
      lightGray: baseTheme.lightGray,
      borderColor: baseTheme.borderColor,
      tableHeaderBg: baseTheme.paperStyle == PdfPaperStyle.minimalDividers
          ? baseTheme.tableHeaderBg
          : pPdf,
      tableHeaderTextColor: baseTheme.paperStyle == PdfPaperStyle.minimalDividers
          ? baseTheme.tableHeaderTextColor
          : PdfColors.white,
      accentColor: aPdf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_id': themeId.value,
      'primary_color': primaryColor.toARGB32(),
      'secondary_color': secondaryColor.toARGB32(),
      'accent_color': accentColor.toARGB32(),
      'font_family': fontFamily.key,
      'density': density.key,
      'header_position': headerPosition.key,
      'address_layout': addressLayout.key,
      'show_bank_details': showBankDetails,
      'show_upi_details': showUpiDetails,
      'show_signature': showSignature,
      'show_notes': showNotes,
      'show_tax_column': showTaxColumn,
      'show_unit_price': showUnitPrice,
      'show_quantity': showQuantity,
      'custom_footer_message': customFooterMessage,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory InvoiceCustomizationConfig.fromJson(Map<String, dynamic> json) {
    final themeIdStr = json['theme_id'] as String?;
    final theme = PdfTheme.fromId(themeIdStr);

    final pInt = json['primary_color'] as int?;
    final sInt = json['secondary_color'] as int?;
    final aInt = json['accent_color'] as int?;

    return InvoiceCustomizationConfig(
      themeId: theme.id,
      primaryColor: pInt != null ? Color(pInt) : theme.previewPrimary,
      secondaryColor: sInt != null ? Color(sInt) : theme.previewSecondary,
      accentColor: aInt != null ? Color(aInt) : theme.previewAccent,
      fontFamily: InvoiceFontFamilyExtension.fromKey(json['font_family'] as String?),
      density: InvoiceDensityExtension.fromKey(json['density'] as String?),
      headerPosition: HeaderPositionExtension.fromKey(json['header_position'] as String?),
      addressLayout: AddressLayoutExtension.fromKey(json['address_layout'] as String?),
      showBankDetails: json['show_bank_details'] as bool? ?? true,
      showUpiDetails: json['show_upi_details'] as bool? ?? true,
      showSignature: json['show_signature'] as bool? ?? true,
      showNotes: json['show_notes'] as bool? ?? true,
      showTaxColumn: json['show_tax_column'] as bool? ?? true,
      showUnitPrice: json['show_unit_price'] as bool? ?? true,
      showQuantity: json['show_quantity'] as bool? ?? true,
      customFooterMessage: json['custom_footer_message'] as String?,
    );
  }

  static InvoiceCustomizationConfig? tryFromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return InvoiceCustomizationConfig.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  static InvoiceCustomizationConfig get defaultConfig =>
      InvoiceCustomizationConfig.fromTheme(PdfTheme.defaultTheme);
}
