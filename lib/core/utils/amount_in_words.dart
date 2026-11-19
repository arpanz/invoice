/// Writes an amount in English words, as Indian tax invoices show it,
/// e.g. 125000.5 → "Rupees One Lakh Twenty Five Thousand and Fifty Paise Only".
class AmountInWords {
  AmountInWords._();

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
    'Eighteen', 'Nineteen',
  ];
  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety',
  ];

  /// Currencies this can name. Others return null.
  static const _units = {'INR': ('Rupees', 'Paise')};

  static bool supports(String currencyCode) => _units.containsKey(currencyCode);

  /// The amount in words, or null if [currencyCode] is not supported or the
  /// amount is negative or too large to name (a hundred thousand crore).
  static String? format(double amount, String currencyCode) {
    final units = _units[currencyCode];
    if (units == null || amount.isNaN || amount < 0) return null;
    final totalMinor = (amount * 100).round();
    final major = totalMinor ~/ 100;
    final minor = totalMinor % 100;
    if (major >= 1000000000000) return null;

    final parts = <String>[units.$1, major == 0 ? 'Zero' : _indian(major)];
    if (minor > 0) parts.add('and ${_belowHundred(minor)} ${units.$2}');
    parts.add('Only');
    return parts.join(' ');
  }

  /// Indian grouping: crore (10^7), lakh (10^5), thousand, hundred.
  static String _indian(int n) {
    final words = <String>[];
    final crore = n ~/ 10000000;
    if (crore > 0) {
      words.add('${_indian(crore)} Crore');
      n %= 10000000;
    }
    for (final (size, name) in const [(100000, 'Lakh'), (1000, 'Thousand'), (100, 'Hundred')]) {
      final count = n ~/ size;
      if (count > 0) {
        words.add('${_belowHundred(count)} $name');
        n %= size;
      }
    }
    if (n > 0) words.add(_belowHundred(n));
    return words.join(' ');
  }

  static String _belowHundred(int n) {
    if (n < 20) return _ones[n];
    final rest = n % 10;
    return rest == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]} ${_ones[rest]}';
  }
}
