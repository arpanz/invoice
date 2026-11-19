import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/number_text.dart';
import 'package:invoice/core/utils/payment_terms.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/services/invoice_render_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('F59: design resolution order', () {
    final ownConfig = const InvoiceCustomizationConfig(themeId: PdfThemeId.nordicFrame).toJsonString();
    final defaultConfig = const InvoiceCustomizationConfig(themeId: PdfThemeId.slateElegance).toJsonString();

    test('a template picked for the invoice beats a saved default design', () {
      final d = InvoiceRenderService.designFrom(
        ownTheme: PdfThemeId.emeraldExecutive.value,
        defaultConfig: defaultConfig,
      );
      expect(d.themeId, PdfThemeId.emeraldExecutive);
    });

    test('the invoice\'s own design beats everything', () {
      final d = InvoiceRenderService.designFrom(
        ownConfig: ownConfig,
        ownTheme: PdfThemeId.emeraldExecutive.value,
        defaultConfig: defaultConfig,
      );
      expect(d.themeId, PdfThemeId.nordicFrame);
    });

    test('defaults apply when the invoice has nothing of its own', () {
      expect(InvoiceRenderService.designFrom(defaultConfig: defaultConfig).themeId, PdfThemeId.slateElegance);
      expect(
        InvoiceRenderService.designFrom(defaultTheme: PdfThemeId.leftRibbon.value).themeId,
        PdfThemeId.leftRibbon,
      );
      expect(InvoiceRenderService.designFrom().themeId, PdfThemeId.classicBlue);
    });

    test('F55: the old enum-name theme ids still resolve', () {
      expect(PdfTheme.fromId('emeraldExecutive').id, PdfThemeId.emeraldExecutive);
    });
  });

  group('custom default design reaches new documents', () {
    // A default that differs from its plain template in more than the id.
    const customDefault = InvoiceCustomizationConfig(
      themeId: PdfThemeId.slateElegance,
      showQuantity: false,
      customFooterMessage: 'Thank you',
    );

    test('no custom default when the default is a plain template or unset', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await InvoiceRenderService.defaultCustomDesign(), isNull);

      SharedPreferences.setMockInitialValues({'default_pdf_theme': PdfThemeId.leftRibbon.value});
      expect(await InvoiceRenderService.defaultCustomDesign(), isNull);

      SharedPreferences.setMockInitialValues({'default_invoice_customization': 'not json'});
      expect(await InvoiceRenderService.defaultCustomDesign(), isNull);
    });

    test('a new invoice that stores only the template id loses the custom default', () async {
      // What the editor did before: this is why it must store the full design.
      SharedPreferences.setMockInitialValues({
        'default_invoice_customization': customDefault.toJsonString(),
        'default_pdf_theme': customDefault.themeId.value,
      });
      await InvoiceRenderService.saveThemeForInvoice('inv-1', PdfTheme.fromId(customDefault.themeId.value));
      final d = await InvoiceRenderService.designForInvoice('inv-1');
      expect(d.themeId, PdfThemeId.slateElegance);
      expect(d.customFooterMessage, isNull);
      expect(d.showQuantity, isTrue);
    });

    test('a new invoice that stores the inherited design keeps it, also after the default changes', () async {
      SharedPreferences.setMockInitialValues({
        'default_invoice_customization': customDefault.toJsonString(),
        'default_pdf_theme': customDefault.themeId.value,
      });
      final inherited = await InvoiceRenderService.defaultCustomDesign();
      expect(inherited, isNotNull);
      expect(inherited!.toJsonString(), customDefault.toJsonString());

      await InvoiceRenderService.saveDesignForInvoice('inv-1', inherited);
      var d = await InvoiceRenderService.designForInvoice('inv-1');
      expect(d.toJsonString(), customDefault.toJsonString());

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('default_invoice_customization');
      await prefs.setString('default_pdf_theme', PdfThemeId.leftRibbon.value);
      d = await InvoiceRenderService.designForInvoice('inv-1');
      expect(d.toJsonString(), customDefault.toJsonString());
    });

    test('picking a plain template for the invoice still replaces the inherited design', () async {
      SharedPreferences.setMockInitialValues({
        'default_invoice_customization': customDefault.toJsonString(),
      });
      await InvoiceRenderService.saveDesignForInvoice('inv-1', customDefault);
      await InvoiceRenderService.saveThemeForInvoice('inv-1', PdfTheme.fromId(PdfThemeId.nordicFrame.value));
      final d = await InvoiceRenderService.designForInvoice('inv-1');
      expect(d.themeId, PdfThemeId.nordicFrame);
      expect(d.customFooterMessage, isNull);
    });
  });

  group('F8: issuer snapshot', () {
    test('parses a snapshot and ignores blank fields', () {
      final p = InvoiceRenderService.profileFromSnapshot(
        '{"businessName":"Acme","gstin":"  ","bankName":"SBI"}',
        'INR',
      )!;
      expect(p.businessName, 'Acme');
      expect(p.gstin, isNull);
      expect(p.bankName, 'SBI');
    });

    test('an unreadable snapshot falls back (null)', () {
      expect(InvoiceRenderService.profileFromSnapshot('not json', 'INR'), isNull);
      expect(InvoiceRenderService.profileFromSnapshot(null, 'INR'), isNull);
    });
  });

  test('F15: payment terms labels', () {
    expect(paymentTermsDays('Due on Receipt'), 0);
    expect(paymentTermsDays('Net 30'), 30);
    expect(paymentTermsDays(null), 7);
  });

  test('F27: typed amounts', () {
    expect(NumberText.parse('₹1,250.50'), 1250.5);
    expect(NumberText.parse('12,5'), 12.5);
    expect(NumberText.parse('1,500'), 1500);
    expect(NumberText.parse('-20'), -20);
    expect(NumberText.parse('abc', fallback: 3), 3);
  });
}
