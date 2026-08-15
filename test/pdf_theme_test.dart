import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/features/invoices/models/invoice_model.dart';
import 'package:invoice/features/invoices/models/line_item_model.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/screens/create_invoice_screen.dart';
import 'package:invoice/features/invoices/screens/invoice_preview_screen.dart';
import 'package:invoice/features/invoices/services/dummy_invoice_data.dart';
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
    test('PdfTheme contains exactly 10 clean, professional themes', () {
      expect(PdfTheme.all.length, 10);
      expect(PdfTheme.all.map((t) => t.id).toList(), [
        PdfThemeId.classicBlue,
        PdfThemeId.modernMinimal,
        PdfThemeId.emeraldExecutive,
        PdfThemeId.slateElegance,
        PdfThemeId.warmCorporate,
        PdfThemeId.nordicFrame,
        PdfThemeId.leftRibbon,
        PdfThemeId.geometricBlock,
        PdfThemeId.securityGrid,
        PdfThemeId.splitTwoTone,
      ]);
    });

    test('PdfTheme.fromId resolves valid themes and falls back safely', () {
      expect(PdfTheme.fromId('classic_blue').id, PdfThemeId.classicBlue);
      expect(PdfTheme.fromId('modern_minimal').id, PdfThemeId.modernMinimal);
      expect(PdfTheme.fromId('emerald_executive').id, PdfThemeId.emeraldExecutive);
      expect(PdfTheme.fromId('slate_elegance').id, PdfThemeId.slateElegance);
      expect(PdfTheme.fromId('warm_corporate').id, PdfThemeId.warmCorporate);
      expect(PdfTheme.fromId('nordic_frame').id, PdfThemeId.nordicFrame);
      expect(PdfTheme.fromId('left_ribbon').id, PdfThemeId.leftRibbon);
      expect(PdfTheme.fromId('geometric_block').id, PdfThemeId.geometricBlock);
      expect(PdfTheme.fromId('security_grid').id, PdfThemeId.securityGrid);
      expect(PdfTheme.fromId('split_two_tone').id, PdfThemeId.splitTwoTone);
      expect(PdfTheme.fromId('unknown_theme').id, PdfThemeId.classicBlue);
      expect(PdfTheme.fromId(null).id, PdfThemeId.classicBlue);
    });
  });

  group('PdfGeneratorService 10 Themes & Paper Styles Rendering', () {
    for (final theme in PdfTheme.all) {
      test('generates valid PDF bytes for ${theme.name} (${theme.paperDesignName})', () async {
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

    test('generates sample live preview with dummy logo and signature', () async {
      final bytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: DummyInvoiceData.sampleInvoice,
        businessProfile: DummyInvoiceData.sampleProfile,
        isPro: true,
        theme: PdfTheme.nordicFrame,
        isSamplePreview: true,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

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
    testWidgets('renders 2-column live preview grid and allows selection', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Choose Invoice Style'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      // Tap on the 2nd template card in the 2-column grid (Modern Minimal)
      final gridCards = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(GestureDetector),
      );
      expect(gridCards, findsWidgets);
      await tester.tap(gridCards.at(1));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Apply Selected Style button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 200));

      expect(selectedResult, isNotNull);
      expect(selectedResult!.id, PdfThemeId.modernMinimal);
      expect(defaultSaved, isFalse);
    });
  });

  group('CreateInvoiceScreen & InvoicePreviewScreen Theme Integration', () {
    testWidgets('CreateInvoiceScreen shows Templates card and opens theme picker', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(const CreateInvoiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Choose style & paper design'), findsOneWidget);

      // Tap Templates card to open theme picker sheet
      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Invoice Style'), findsOneWidget);

      // Select 2nd style and apply
      final gridCards = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(gridCards.at(1));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.descendant(
          of: find.byType(PdfThemePickerSheet),
          matching: find.byType(ElevatedButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Choose style & paper design'), findsOneWidget);
    });

    testWidgets('InvoicePreviewScreen shows quick theme pill and actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithProviders(InvoicePreviewScreen(invoice: testInvoice)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.text('Style'), findsOneWidget);
    });
  });
}
