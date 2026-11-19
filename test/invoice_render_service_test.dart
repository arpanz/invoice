import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/number_text.dart';
import 'package:invoice/core/utils/payment_terms.dart';
import 'package:invoice/features/invoices/models/invoice_customization_config.dart';
import 'package:invoice/features/invoices/models/pdf_theme.dart';
import 'package:invoice/features/invoices/services/invoice_render_service.dart';

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
