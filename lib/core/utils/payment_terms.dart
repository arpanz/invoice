/// Days until payment is due for a payment-terms label from onboarding or
/// Settings: "Due on Receipt" → 0, "Net 30" → 30. Unknown or unset → 7.
int paymentTermsDays(String? terms) {
  if (terms == null) return 7;
  final t = terms.toLowerCase();
  if (t.contains('receipt')) return 0;
  final m = RegExp(r'(\d{1,3})').firstMatch(t);
  return m != null ? int.parse(m.group(1)!) : 7;
}
