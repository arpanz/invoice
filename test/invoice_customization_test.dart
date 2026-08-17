import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/estimates/models/estimate_model.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/services/dummy_invoice_data.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';
import 'package:invoice/features/invoices/widgets/invoice_customizer_studio_sheet.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => BillingService()),
      ],
      child: MaterialApp(home: child),
    );
  }

  final testInvoice = InvoiceModel(
    id: 'test-custom-inv-1',
    invoiceNumber: 'INV-2026-001',
    clientName: 'Acme Corporation',
    clientEmail: 'billing@acme.org',
    clientPhone: '+1 800 555 0199',
    clientAddress: '500 Tech Boulevard, Silicon Valley, CA',
    clientGstin: 'US12345678',
    invoiceDate: DateTime(2026, 8, 16),
    dueDate: DateTime(2026, 8, 30),
    subtotal: 2500.0,
    discountType: DiscountType.percentage,
    discountValue: 10.0,
    discountAmount: 250.0,
    sgstRate: 0,
    cgstRate: 0,
    igstRate: 18.0,
    taxAmount: 405.0,
    grandTotal: 2655.0,
    status: InvoiceStatus.unpaid,
    notes: 'Payment terms: Net 15 days upon receipt.',
    currency: 'USD',
    createdAt: DateTime(2026, 8, 16),
    updatedAt: DateTime(2026, 8, 16),
    lineItems: const [
      LineItemModel(
        id: 'li-1',
        invoiceId: 'test-custom-inv-1',
        description: 'Cloud Infrastructure & Architecture Consultation',
        quantity: 10,
        unitPrice: 200.0,
        total: 2000.0,
      ),
      LineItemModel(
        id: 'li-2',
        invoiceId: 'test-custom-inv-1',
        description: 'Security Review & Penetration Testing Report',
        quantity: 1,
        unitPrice: 500.0,
        total: 500.0,
      ),
    ],
  );

  const testProfile = BusinessProfile(
    businessName: 'NextGen Engineering Inc',
    address: '100 Innovation Parkway, Austin, TX',
    phone: '+1 512 555 7890',
    email: 'finance@nextgen.io',
    gstin: 'US98765432',
    bankName: 'Silicon Valley Commercial Bank',
    accountNumber: '1122334455',
    ifscCode: 'SVCB000789',
    upiId: 'nextgen@upi',
    currency: 'USD',
  );

  group('InvoiceCustomizationConfig Unit Tests', () {
    test('Default configuration matches expected values', () {
      final config = InvoiceCustomizationConfig.defaultConfig;
      expect(config.themeId, PdfThemeId.classicBlue);
      expect(config.fontFamily, InvoiceFontFamily.cleanSans);
      expect(config.density, InvoiceDensity.regular);
      expect(config.headerPosition, HeaderPosition.logoLeftDetailsRight);
      expect(config.addressLayout, AddressLayout.sideBySide);
      expect(config.showBankDetails, true);
      expect(config.showUpiDetails, true);
      expect(config.showSignature, true);
      expect(config.showNotes, true);
      expect(config.showUnitPrice, true);
      expect(config.showQuantity, true);
      expect(config.customFooterMessage, null);
    });

    test('copyWith updates fields immutably', () {
      final base = InvoiceCustomizationConfig.defaultConfig;
      final updated = base.copyWith(
        themeId: PdfThemeId.emeraldExecutive,
        fontFamily: InvoiceFontFamily.editorialSerif,
        density: InvoiceDensity.compact,
        headerPosition: HeaderPosition.centeredLogo,
        addressLayout: AddressLayout.stacked,
        showSignature: false,
        customFooterMessage: 'Custom Thanks!',
      );

      expect(updated.themeId, PdfThemeId.emeraldExecutive);
      expect(updated.fontFamily, InvoiceFontFamily.editorialSerif);
      expect(updated.density, InvoiceDensity.compact);
      expect(updated.density.scaleFactor, 0.86);
      expect(updated.headerPosition, HeaderPosition.centeredLogo);
      expect(updated.addressLayout, AddressLayout.stacked);
      expect(updated.showSignature, false);
      expect(updated.customFooterMessage, 'Custom Thanks!');
      expect(base.showSignature, true); // original unaffected
    });

    test('JSON serialization & deserialization roundtrip', () {
      final original = InvoiceCustomizationConfig(
        themeId: PdfThemeId.nordicFrame,
        primaryColor: const Color(0xFF0F766E),
        secondaryColor: const Color(0xFF115E59),
        accentColor: const Color(0xFF14B8A6),
        fontFamily: InvoiceFontFamily.modernMono,
        density: InvoiceDensity.spacious,
        headerPosition: HeaderPosition.logoRightDetailsLeft,
        addressLayout: AddressLayout.inverted,
        showBankDetails: false,
        showUpiDetails: true,
        showSignature: true,
        showNotes: false,
        showTaxColumn: true,
        showUnitPrice: true,
        showQuantity: false,
        customFooterMessage: 'Please wire funds within 14 business days.',
      );

      final jsonStr = original.toJsonString();
      final parsed = InvoiceCustomizationConfig.tryFromJsonString(jsonStr);

      expect(parsed, isNotNull);
      expect(parsed!.themeId, PdfThemeId.nordicFrame);
      expect(parsed.primaryColor.toARGB32(), original.primaryColor.toARGB32());
      expect(parsed.fontFamily, InvoiceFontFamily.modernMono);
      expect(parsed.density, InvoiceDensity.spacious);
      expect(parsed.density.scaleFactor, 1.14);
      expect(parsed.headerPosition, HeaderPosition.logoRightDetailsLeft);
      expect(parsed.addressLayout, AddressLayout.inverted);
      expect(parsed.showBankDetails, false);
      expect(parsed.showNotes, false);
      expect(parsed.showQuantity, false);
      expect(parsed.customFooterMessage, 'Please wire funds within 14 business days.');
    });

    test('toPdfTheme converts custom colors to PdfColor accurately', () {
      final config = InvoiceCustomizationConfig(
        themeId: PdfThemeId.classicBlue,
        primaryColor: const Color(0xFF991B1B),
        secondaryColor: const Color(0xFF7F1D1D),
        accentColor: const Color(0xFFEF4444),
      );

      final pdfTheme = config.toPdfTheme();
      expect(pdfTheme.id, PdfThemeId.classicBlue);
      expect(pdfTheme.previewPrimary, const Color(0xFF991B1B));
    });
  });

  group('PdfGeneratorService Customization Rendering Tests', () {
    test('Generates valid PDF with all font families', () async {
      for (final font in InvoiceFontFamily.values) {
        final config = InvoiceCustomizationConfig.defaultConfig.copyWith(fontFamily: font);
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: testInvoice,
          businessProfile: testProfile,
          isPro: true,
          customizationConfig: config,
        );
        expect(pdfBytes.isNotEmpty, true);
        expect(pdfBytes.length, greaterThan(1000));
      }
    });

    test('Generates valid PDF with all densities (Compact, Regular, Spacious)', () async {
      for (final density in InvoiceDensity.values) {
        final config = InvoiceCustomizationConfig.defaultConfig.copyWith(density: density);
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: testInvoice,
          businessProfile: testProfile,
          isPro: true,
          customizationConfig: config,
        );
        expect(pdfBytes.isNotEmpty, true);
      }
    });

    test('Generates valid PDF with all HeaderPosition variations', () async {
      for (final pos in HeaderPosition.values) {
        final config = InvoiceCustomizationConfig.defaultConfig.copyWith(headerPosition: pos);
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: testInvoice,
          businessProfile: testProfile,
          isPro: true,
          customizationConfig: config,
        );
        expect(pdfBytes.isNotEmpty, true);
      }
    });

    test('Generates valid PDF with all AddressLayout variations', () async {
      for (final layout in AddressLayout.values) {
        final config = InvoiceCustomizationConfig.defaultConfig.copyWith(addressLayout: layout);
        final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: testInvoice,
          businessProfile: testProfile,
          isPro: true,
          customizationConfig: config,
        );
        expect(pdfBytes.isNotEmpty, true);
      }
    });

    test('Generates valid PDF with custom section toggles & footer notes', () async {
      final config = InvoiceCustomizationConfig.defaultConfig.copyWith(
        showBankDetails: false,
        showUpiDetails: false,
        showSignature: false,
        showNotes: false,
        showQuantity: false,
        showUnitPrice: false,
        customFooterMessage: 'Wire transfer instructions on file.',
      );

      final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: testInvoice,
        businessProfile: testProfile,
        isPro: true,
        customizationConfig: config,
      );
      expect(pdfBytes.isNotEmpty, true);
    });

    test('Generates valid Estimate PDF with custom design configuration', () async {
      final config = InvoiceCustomizationConfig.defaultConfig.copyWith(
        themeId: PdfThemeId.emeraldExecutive,
        density: InvoiceDensity.compact,
        headerPosition: HeaderPosition.centeredLogo,
      );

      final pdfBytes = await PdfGeneratorService.generateEstimatePdf(
        estimate: DummyInvoiceData.sampleInvoice.toEstimate(),
        businessProfile: testProfile,
        isPro: true,
        customizationConfig: config,
      );
      expect(pdfBytes.isNotEmpty, true);
    });
  });

  group('InvoiceCustomizerStudioSheet Widget Tests', () {
    testWidgets('Renders all 4 studio tabs and controls', (tester) async {
      InvoiceCustomizationConfig? savedResult;

      await tester.pumpWidget(
        wrapWithProviders(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  final res = await InvoiceCustomizerStudioSheet.show(
                    ctx,
                    initialConfig: InvoiceCustomizationConfig.defaultConfig,
                    invoice: testInvoice,
                    businessProfile: testProfile,
                  );
                  savedResult = res;
                },
                child: const Text('Open Studio'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open studio
      await tester.tap(find.text('Open Studio'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header and tabs exist
      expect(find.text('Invoice Design Studio'), findsOneWidget);
      expect(find.text('Style'), findsOneWidget);
      expect(find.text('Typo'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Sections'), findsOneWidget);

      // Verify Style Tab contents (Paper Design Template, Color Palettes)
      expect(find.text('PAPER DESIGN TEMPLATE', skipOffstage: false), findsOneWidget);
      expect(find.text('COLOR PALETTE PRESETS', skipOffstage: false), findsOneWidget);

      // Switch to Typography Tab
      await tester.tap(find.text('Typo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('FONT FAMILY', skipOffstage: false), findsOneWidget);
      expect(find.text('Clean Sans', skipOffstage: false), findsOneWidget);
      expect(find.text('Editorial Serif', skipOffstage: false), findsOneWidget);

      // Scroll down in typography tab
      await tester.drag(find.byType(ListView).last, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('DOCUMENT DENSITY & SIZING', skipOffstage: false), findsOneWidget);
      expect(find.text('Compact', skipOffstage: false), findsOneWidget);
      expect(find.text('Regular', skipOffstage: false), findsOneWidget);
      expect(find.text('Spacious', skipOffstage: false), findsOneWidget);

      // Switch to Layout Tab
      await tester.tap(find.text('Layout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('HEADER ALIGNMENT & POSITION', skipOffstage: false), findsOneWidget);
      expect(find.text('Left Logo', skipOffstage: false), findsOneWidget);
      expect(find.text('Right Logo', skipOffstage: false), findsOneWidget);
      expect(find.text('Centered', skipOffstage: false), findsOneWidget);

      // Scroll down in layout tab
      await tester.drag(find.byType(ListView).last, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ADDRESS BLOCK ARRANGEMENT', skipOffstage: false), findsOneWidget);
      expect(find.text('Side by Side', skipOffstage: false), findsOneWidget);
      expect(find.text('Inverted', skipOffstage: false), findsOneWidget);
      expect(find.text('Stacked', skipOffstage: false), findsOneWidget);

      // Switch to Sections Tab
      await tester.tap(find.text('Sections'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('DOCUMENT SECTIONS VISIBILITY', skipOffstage: false), findsOneWidget);
      expect(find.text('Bank Payment Details', skipOffstage: false), findsOneWidget);
      expect(find.text('Digital UPI / Payment ID', skipOffstage: false), findsOneWidget);
      expect(find.text('Signature & Sign-Off', skipOffstage: false), findsOneWidget);

      // Scroll down in sections tab
      await tester.drag(find.byType(ListView).last, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('TABLE COLUMNS', skipOffstage: false), findsOneWidget);
      expect(find.text('CUSTOM FOOTER CLOSING MESSAGE', skipOffstage: false), findsOneWidget);

      // Tap Apply & Save Style
      await tester.tap(find.text('Apply & Save Style'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(savedResult, isNotNull);
    });
  });
}

extension on InvoiceModel {
  EstimateModel toEstimate() {
    return EstimateModel(
      id: 'est-1',
      estimateNumber: 'EST-2026-001',
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      clientGstin: clientGstin,
      estimateDate: invoiceDate,
      expiryDate: dueDate,
      subtotal: subtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      sgstRate: sgstRate,
      cgstRate: cgstRate,
      igstRate: igstRate,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      status: EstimateStatus.pending,
      notes: notes,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lineItems: lineItems,
    );
  }
}
