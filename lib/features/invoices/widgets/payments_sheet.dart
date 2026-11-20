import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../../../core/theme/app_icons.dart';

/// Payment methods offered when recording a payment.
const paymentMethods = ['Bank transfer', 'UPI', 'Cash', 'Card', 'Cheque', 'PayPal'];

/// Lists an invoice's payments, with "Record payment" and per-payment delete.
/// Returns true if anything changed.
class PaymentsSheet extends StatefulWidget {
  final InvoiceModel invoice;

  const PaymentsSheet({super.key, required this.invoice});

  static Future<bool> show(BuildContext context, InvoiceModel invoice) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PaymentsSheet(invoice: invoice),
    );
    return changed ?? false;
  }

  @override
  State<PaymentsSheet> createState() => _PaymentsSheetState();
}

class _PaymentsSheetState extends State<PaymentsSheet> {
  List<PaymentModel> _payments = [];
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final payments = await DbProvider.paymentsFor(widget.invoice.id);
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _loading = false;
    });
  }

  double get _paid => _payments.fold(0.0, (sum, p) => sum + p.amount);
  double get _balance => widget.invoice.grandTotal - _paid;

  String _money(double v) => CurrencyFormatter.format(v, currencyCode: widget.invoice.currency);

  Future<void> _record() async {
    final payment = await RecordPaymentSheet.show(
      context,
      invoice: widget.invoice,
      balance: _balance,
    );
    if (payment == null) return;
    await DbProvider.addPayment(payment);
    _changed = true;
    await _load();
  }

  Future<void> _delete(PaymentModel p) async {
    final ok = await AppDialog.showDelete(
      context: context,
      title: 'Delete payment?',
      message: 'Delete the ${_money(p.amount)} payment from '
          '${DateFormat('d MMM yyyy').format(p.paidOn)}?',
    );
    if (ok != true) return;
    await DbProvider.deletePayment(p.id);
    _changed = true;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final overpaid = -_balance;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Payments',
                  style: AppTypography.serif(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'Invoice ${widget.invoice.invoiceNumber} · Total ${_money(widget.invoice.grandTotal)}',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _summary('Received', _money(_paid), AppColors.statusPaid),
                    const SizedBox(width: 10),
                    overpaid > 0.005
                        ? _summary('Overpaid by', _money(overpaid), AppColors.statusPartiallyPaid)
                        : _summary('Balance due', _money(_balance < 0 ? 0 : _balance), AppColors.ink),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No payments recorded yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _payments.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.hairline),
                      itemBuilder: (_, i) {
                        final p = _payments[i];
                        final details = [
                          DateFormat('d MMM yyyy').format(p.paidOn),
                          if (p.method != null && p.method!.isNotEmpty) p.method!,
                          if (p.note != null && p.note!.isNotEmpty) p.note!,
                        ].join(' · ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _money(p.amount),
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                          subtitle: Text(details, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          trailing: IconButton(
                            tooltip: 'Delete payment',
                            icon: Icon(AppIcons.delete, color: AppColors.muted),
                            onPressed: () => _delete(p),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _record,
                  icon: const Icon(AppIcons.add),
                  label: const Text('Record payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Form for one payment: amount (defaults to the balance), date, method and
/// note. Returns the payment, or null if cancelled. Saving is the caller's job.
class RecordPaymentSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final double balance;

  const RecordPaymentSheet({super.key, required this.invoice, required this.balance});

  static Future<PaymentModel?> show(
    BuildContext context, {
    required InvoiceModel invoice,
    required double balance,
  }) {
    return showModalBottomSheet<PaymentModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecordPaymentSheet(invoice: invoice, balance: balance),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late final TextEditingController _amountCtrl;
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DateTime _paidOn;
  String? _method;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paidOn = DateTime(now.year, now.month, now.day);
    _amountCtrl = TextEditingController(
      text: widget.balance > 0.005 ? NumberText.trim(double.parse(widget.balance.toStringAsFixed(2))) : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _paidOn = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      PaymentModel(
        id: const Uuid().v4(),
        invoiceId: widget.invoice.id,
        amount: double.parse(NumberText.parse(_amountCtrl.text).toStringAsFixed(2)),
        paidOn: _paidOn,
        method: _method,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyFormatter.getCurrencySymbol(widget.invoice.currency);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record payment',
                  style: AppTypography.serif(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Amount received',
                  controller: _amountCtrl,
                  prefixText: '$symbol ',
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final amount = NumberText.parse(v, fallback: double.nan);
                    if (amount.isNaN || amount <= 0) return 'Enter an amount above 0';
                    return null;
                  },
                ),
                if (widget.balance > 0.005) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Balance due: ${CurrencyFormatter.format(widget.balance, currencyCode: widget.invoice.currency)}',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date received'),
                    child: Text(DateFormat('d MMM yyyy').format(_paidOn)),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in paymentMethods)
                      ChoiceChip(
                        label: Text(m),
                        selected: _method == m,
                        onSelected: (sel) => setState(() => _method = sel ? m : null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(label: 'Note (optional)', controller: _noteCtrl),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: const Text('Save payment')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
