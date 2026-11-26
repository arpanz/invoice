import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../receipts/receipt_pdf_service.dart';
import '../../receipts/receipt_preview_screen.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../../../core/theme/app_icons.dart';

/// Payment methods offered when recording a payment.
const paymentMethods = ['Bank transfer', 'UPI', 'Cash', 'Card', 'Cheque', 'PayPal'];

/// Lists an invoice's payments, with "Record payment" and per-payment delete.
/// Returns true if anything changed.
class PaymentsSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onChanged;

  const PaymentsSheet({super.key, required this.invoice, this.onChanged});

  static Future<bool> show(BuildContext context, InvoiceModel invoice) async {
    var changed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PaymentsSheet(
        invoice: invoice,
        onChanged: () => changed = true,
      ),
    );
    return changed;
  }

  @override
  State<PaymentsSheet> createState() => _PaymentsSheetState();
}

class _PaymentsSheetState extends State<PaymentsSheet> {
  List<PaymentModel> _payments = [];
  bool _loading = true;
  final _messages = GlobalKey<ScaffoldMessengerState>();

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
    widget.onChanged?.call();
    await _load();
    if (!mounted) return;
    _messages.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentRecorded),
          action: SnackBarAction(
            label: context.l10n.sendReceipt,
            onPressed: () => _openReceipt(payment),
          ),
        ),
      );
  }

  void _openReceipt(PaymentModel payment) {
    if (!_payments.any((entry) => entry.id == payment.id)) return;
    ReceiptPreviewScreen.open(
      context,
      PaymentReceipt.fromPayments(widget.invoice, _payments, payment: payment),
    );
  }

  Future<void> _delete(PaymentModel p) async {
    final ok = await AppDialog.showDelete(
      context: context,
      title: context.l10n.deletePayment,
      message: context.l10n.deleteThePaymentFrom(_money(p.amount), DateFormat('d MMM yyyy', context.localeName).format(p.paidOn)),
    );
    if (ok != true) return;
    await DbProvider.deletePayment(p.id);
    widget.onChanged?.call();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final overpaid = -_balance;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: ScaffoldMessenger(
          key: _messages,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
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
                    context.l10n.payments,
                    style: AppTypography.serif(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.invoiceTotal(widget.invoice.invoiceNumber, _money(widget.invoice.grandTotal)),
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summary(context.l10n.received, _money(_paid), AppColors.statusPaid),
                      const SizedBox(width: 10),
                      overpaid > 0.005
                          ? _summary(context.l10n.overpaidBy, _money(overpaid), AppColors.statusPartiallyPaid)
                          : _summary(context.l10n.balanceDueLabel, _money(_balance < 0 ? 0 : _balance), AppColors.ink),
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
                        context.l10n.noPaymentsRecordedYet,
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
                            DateFormat('d MMM yyyy', context.localeName).format(p.paidOn),
                            if (p.method != null && p.method!.isNotEmpty) context.l10n.catalogLabel(p.method!),
                            if (p.note != null && p.note!.isNotEmpty) p.note!,
                          ].join(' · ');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _money(p.amount),
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                            subtitle: Text(details, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _openReceipt(p),
                                  child: Text(context.l10n.receipt),
                                ),
                                IconButton(
                                  tooltip: context.l10n.deletePayment2,
                                  icon: Icon(AppIcons.delete, color: AppColors.muted),
                                  onPressed: () => _delete(p),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _record,
                    icon: const Icon(AppIcons.add),
                    label: Text(context.l10n.recordPayment),
                  ),
                ],
              ),
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
                  context.l10n.recordPayment,
                  style: AppTypography.serif(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.l10n.amountReceived,
                  controller: _amountCtrl,
                  prefixText: '$symbol ',
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final amount = NumberText.parse(v, fallback: double.nan);
                    if (amount.isNaN || amount <= 0) return context.l10n.enterAnAmountAbove0;
                    return null;
                  },
                ),
                if (widget.balance > 0.005) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.remainingAmountLabel(CurrencyFormatter.format(widget.balance, currencyCode: widget.invoice.currency)),
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: context.l10n.dateReceived),
                    child: Text(DateFormat('d MMM yyyy', context.localeName).format(_paidOn)),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in paymentMethods)
                      ChoiceChip(
                        label: Text(context.l10n.catalogLabel(m)),
                        selected: _method == m,
                        onSelected: (sel) => setState(() => _method = sel ? m : null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(label: context.l10n.noteOptional, controller: _noteCtrl),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: Text(context.l10n.savePayment)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
