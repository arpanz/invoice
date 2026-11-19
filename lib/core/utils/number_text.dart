/// Formats plain numbers (quantities, rates, percentages) for display and for
/// pre-filling text fields, without losing precision.
///
/// Use this instead of `toString().replaceAll('.0', '')`, which turns 1.05
/// into "15", or `toStringAsFixed(0)`, which turns a 2.5% rate into "3".
class NumberText {
  NumberText._();

  /// Shortest text for [value] with at most [maxDecimals] decimals and no
  /// trailing zeros: 10.0 → "10", 1.05 → "1.05", 8.875 → "8.875".
  static String trim(num value, {int maxDecimals = 4}) {
    if (value.isNaN || value.isInfinite) return '0';
    var text = value.toDouble().toStringAsFixed(maxDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    if (text == '-0') text = '0';
    return text;
  }

  /// Reads a number typed by a person: ignores spaces, thousands commas and
  /// currency symbols ("₹1,250.50" → 1250.5). Returns [fallback] when there is
  /// no number. A lone comma with up to two digits after it is read as a
  /// decimal comma ("12,5" → 12.5).
  static double parse(String? text, {double fallback = 0}) {
    if (text == null) return fallback;
    var t = text.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (t.isEmpty) return fallback;
    final commas = ','.allMatches(t).length;
    if (!t.contains('.') && commas == 1 && RegExp(r',\d{1,2}$').hasMatch(t)) {
      t = t.replaceFirst(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite) return fallback;
    return v;
  }
}
