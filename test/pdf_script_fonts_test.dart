import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/pdf_script_fonts.dart';

void main() {
  test('finds only the Indic scripts a document uses', () {
    expect(PdfScriptFonts.scriptsIn('Invoice for Acme ₹1,000'), isEmpty);
    expect(PdfScriptFonts.scriptsIn('राम ट्रेडर्स, चेन्नई'), ['Devanagari']);
    expect(PdfScriptFonts.scriptsIn('சென்னை / ಬೆಂಗಳೂರು / राम'), ['Devanagari', 'Tamil', 'Kannada']);
    // Bengali ships with the app, so it is not downloaded.
    expect(PdfScriptFonts.scriptsIn('কলকাতা'), isEmpty);
  });
}
