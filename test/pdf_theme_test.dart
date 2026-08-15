import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/screens/create_invoice_screen.dart';
import 'package:invoice/features/invoices/screens/invoice_preview_screen.dart';
import 'package:invoice/features/invoices/services/pdf_generator_service.dart';
import 'package:invoice/features/invoices/widgets/pdf_theme_picker_sheet.dart';
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
    id: 'test-theme-inv-1',
    invoiceNumber: 'INV00099',
    clientName: 'Apex Dynamics',
    clientEmail: 'billing@apexdynamics.com',
    clientPhone: '+1 555 123 4567',
    clientAddress: '100 Innovation Way, Suite 400',
    clientGstin: 'US987654321',
    invoiceDate: DateTime(2026, 8, 15),
    dueDate: DateTime(2026, 8, 22),
    subtotal: 1200.0,
    discountType: DiscountType.percentage,
    discountValue: 10.0,
    discountAmount: 120.0,
    sgstRate: 0,
    cgstRate: 0,
    igstRate: 18.0,
    taxAmount: 194.4,
    grandTotal: 1274.4,
    status: InvoiceStatus.unpaid,
    notes: 'Thank you for your business. Net 30 payment terms apply.',
    currency: 'USD',
    createdAt: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 8, 15),
    lineItems: const [
      LineItemModel(
        id: 'li-1',
        invoiceId: 'test-theme-inv-1',
        description: 'Software Architecture Consulting',
        quantity: 8,
        unitPrice: 150.0,
        total: 1200.0,
      ),
    ],
  );

  const testProfile = BusinessProfile(
    businessName: 'Studio Precision LLC',
    address: '42 Wallaby Way, Sydney',
    phone: '+61 2 9999 8888',
    email: 'hello@precision.studio',
    gstin: 'AU123456789',
    bankName: 'Global Commerce Bank',
    accountNumber: '9876543210',
    ifscCode: 'GCB000123',
    currency: 'USD',
  );

  group('PdfTheme Model & Lookups', () {
    test('PdfTheme contains exactly 5 clean, professional themes', () {
      expect(PdfTheme.all.length, 5);
      expect(PdfTheme.all.map((t) => t.id).toList(), [
        PdfThemeId.classicBlue,
        PdfThemeId.modernMinimal,
        PdfThemeId.emeraldExecutive,
        PdfThemeId.slateElegance,
        PdfThemeId.warmCorporate,
      ]);
    });

    test('PdfTheme.fromId resolves valid themes and falls back safely', () {
      expect(PdfTheme.fromId('classic_blue').id, PdfThemeId.classicBlue);
      expect(PdfTheme.fromId('modern_minimal').id, PdfThemeId.modernMinimal);
      expect(PdfTheme.fromId('emerald_executive').id, PdfThemeId.emeraldExecutive);
      expect(PdfTheme.fromId('slate_elegance').id, PdfThemeId.slateElegance);
      expect(PdfTheme.fromId('warm_corporate').id, PdfThemeId.warmCorporate);
      expect(PdfTheme.fromId('unknown_theme').id, PdfThemeId.classicBlue);
      expect(PdfTheme.fromId(null).id, PdfThemeId.classicBlue);
    });
  });

  group('PdfGeneratorService Theme Rendering', () {
    for (final theme in PdfTheme.all) {
      test('generates valid PDF bytes for ${theme.name}', () async {
        final bytes = await PdfGeneratorService.generateInvoicePdf(
          invoice: testInvoice,
          businessProfile: testProfile,
          isPro: true,
          theme: theme,
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(1000));
      });
    }

    test('generates dual tax PDF with free watermark', () async {
      final dualTaxInvoice = testInvoice.copyWith(
        currency: 'INR',
        sgstRate: 9.0,
        cgstRate: 9.0,
        igstRate: 0,
      );
      const inrProfile = BusinessProfile(
        businessName: 'Studio Precision India',
        currency: 'INR',
      );

      final bytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: dualTaxInvoice,
        businessProfile: inrProfile,
        isPro: false,
        theme: PdfTheme.modernMinimal,
      );

      expect(bytes, isNotEmpty);
    });
  });

  group('PdfThemePickerSheet Widget Tests', () {
    testWidgets('renders all 5 theme options and allows selection', (
      WidgetTester tester,
    ) async {
      PdfTheme? selectedResult;
      bool? defaultSaved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfThemePickerSheet(
              currentTheme: PdfTheme.classicBlue,
              onThemeSelected: (theme, setAsDefault) {
                selectedResult = theme;
                defaultSaved = setAsDefault;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF Invoice Themes'), findsOneWidget);
      expect(find.text('Classic Blue'), findsOneWidget);
      expect(find.text('Modern Minimal'), findsOneWidget);
      expect(find.text('Emerald Executive'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Slate Elegance'), 100);
      expect(find.text('Slate Elegance'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Warm Corporate'), 100);
      expect(find.text('Warm Corporate'), findsOneWidget);

      // Tap on Modern Minimal (scroll back if needed)
      await tester.scrollUntilVisible(find.text('Modern Minimal'), -100);
      await tester.tap(find.text('Modern Minimal'));
      await tester.pumpAndSettle();

      // Tap Apply Theme
      await tester.tap(find.text('Apply Theme'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!.id, PdfThemeId.modernMinimal);
      expect(defaultSaved, isFalse);
    });
  });

  group('CreateInvoiceScreen & InvoicePreviewScreen Theme Integration', () {
    testWidgets('CreateInvoiceScreen shows theme on Templates card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithProviders(const CreateInvoiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Classic Blue'), findsOneWidget);

      // Tap Templates card to open theme picker sheet
      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.text('PDF Invoice Themes'), findsOneWidget);
      expect(find.text('Emerald Executive'), findsOneWidget);

      // Select Emerald Executive and apply
      await tester.tap(find.text('Emerald Executive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Emerald Executive'), findsOneWidget);
    });

    testWidgets('InvoicePreviewScreen shows quick theme pill and actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithProviders(InvoicePreviewScreen(invoice: testInvoice)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.text('Classic Blue'), findsOneWidget);
    });
  });
}
