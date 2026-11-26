import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/billing/billing_service.dart';
import 'package:invoice/core/providers/currency_provider.dart';
import 'package:invoice/core/theme/app_colors.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
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
import 'package:invoice/core/theme/app_icons.dart';

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
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
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

  group('PdfTheme Model & Lookups', () {
    test('all 28 themes have unique saved IDs and an ordered category', () {
      expect(PdfTheme.all, hasLength(28));
      expect(PdfTheme.all.map((theme) => theme.id), unorderedEquals(PdfThemeId.values));
      expect(
        PdfTheme.all.map((theme) => theme.category).toSet(),
        unorderedEquals(PdfThemeCategory.values),
      );
      expect(
        PdfThemeCategory.values.map((category) => category.label),
        ['Professional', 'Simple', 'Bold', 'Creative', 'Retail & GST'],
      );
      expect(PdfThemeCategory.values.map((category) => category.order), [0, 1, 2, 3, 4]);

      final ids = PdfTheme.all.map((theme) => theme.id.value).toSet();
      expect(ids, hasLength(28));
      for (final theme in PdfTheme.all) {
        expect(theme.id.value, matches(r'^[a-z]+(?:_[a-z]+)+$'));
        expect(PdfTheme.fromId(theme.id.value), same(theme));
        expect(PdfTheme.fromId(theme.id.name), same(theme));

        final customized = InvoiceCustomizationConfig.fromTheme(theme)
            .copyWith(primaryColor: Colors.black)
            .toPdfTheme();
        expect(customized.category, theme.category);
      }
    });

    test('table headers meet 4.5:1 contrast across all theme palettes', () {
      for (final theme in PdfTheme.all) {
        final foreground = theme.tableHeaderTextColor.luminance;
        final background = theme.tableHeaderBg.luminance;
        final contrast = foreground > background
            ? (foreground + 0.05) / (background + 0.05)
            : (background + 0.05) / (foreground + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: theme.name);
      }
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

  group('PdfGeneratorService theme options', () {
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
    for (final dark in [false, true]) {
      testWidgets('filters, counts and applies a template (dark: $dark)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        AppColors.isDark = dark;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          AppColors.isDark = false;
        });

        PdfTheme? selectedResult;
        bool? defaultSaved;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              body: PdfThemePickerSheet(
                currentTheme: PdfTheme.classicBlue,
                onThemeSelected: (choice, setAsDefault) {
                  selectedResult = choice.theme;
                  expect(choice.customConfig, isNull);
                  defaultSaved = setAsDefault;
                },
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Choose Invoice Style'), findsOneWidget);
        expect(find.text('28 of 28 templates'), findsOneWidget);
        expect(find.text('Classic Corporate'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);

        await tester.tap(find.text('Retail & GST'));
        await tester.pump();
        expect(find.text('5 of 28 templates'), findsOneWidget);
        expect(find.text('Classic Corporate'), findsNothing);
        expect(find.text('Saffron Ledger'), findsOneWidget);

        await tester.tap(find.text('All'));
        await tester.pump();
        expect(find.text('28 of 28 templates'), findsOneWidget);
        expect(find.text('Classic Corporate'), findsOneWidget);

        await tester.tap(find.text('Retail & GST'));
        await tester.pump();
        await tester.tap(find.text('Saffron Ledger'));
        await tester.pump();
        await tester.tap(find.text('Apply Selected Style'));
        await tester.pump();

        expect(selectedResult?.id, PdfThemeId.saffronLedger);
        expect(defaultSaved, isFalse);
      });
    }
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

    testWidgets('InvoicePreviewScreen has one design entry point', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithProviders(InvoicePreviewScreen(invoice: testInvoice)),
      );
      await tester.pump();

      // One entry point for the design, and nothing laid over the page.
      expect(find.byIcon(AppIcons.palette), findsOneWidget);
      expect(find.text('Style'), findsNothing);
    });
  });
}
