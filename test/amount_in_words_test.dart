import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/amount_in_words.dart';

void main() {
  test('Indian grouping with paise', () {
    expect(AmountInWords.format(125000.5, 'INR'),
        'Rupees One Lakh Twenty Five Thousand and Fifty Paise Only');
    expect(AmountInWords.format(1500000000, 'INR'), 'Rupees One Hundred Fifty Crore Only');
    expect(AmountInWords.format(0, 'INR'), 'Rupees Zero Only');
    expect(AmountInWords.format(1018, 'INR'), 'Rupees One Thousand Eighteen Only');
  });

  test('unsupported currency gives null', () {
    expect(AmountInWords.format(10, 'USD'), isNull);
  });
}
