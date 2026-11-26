import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/l10n.dart';

import '../../features/invoices/models/invoice_model.dart';
import '../../features/invoices/services/invoice_render_service.dart';
import '../../shared_widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_typography.dart';
import 'client_reminder_message.dart';

class ClientReminderSheet extends StatefulWidget {
  const ClientReminderSheet._({required this.message, required this.phone});

  final String message;
  final String? phone;

  static Future<void> show(BuildContext context, InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await InvoiceRenderService.profileFor(invoice);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ClientReminderSheet._(
        message: buildClientReminder(
          invoice: invoice,
          l10n: context.l10n,
          now: DateTime.now(),
          businessName: profile.businessName,
          upiId: prefs.getString('biz_upi'),
        ),
        phone: normalizeWhatsAppPhone(
          invoice.clientPhone,
          currency: invoice.currency,
        ),
      ),
    );
  }

  @override
  State<ClientReminderSheet> createState() => _ClientReminderSheetState();
}

class _ClientReminderSheetState extends State<ClientReminderSheet> {
  late final _message = TextEditingController(text: widget.message);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send({bool whatsApp = false}) async {
    if (_busy) return;
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.enterAMessageToSend);
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final phone = widget.phone;
      if (whatsApp && phone != null) {
        try {
          final opened = await launchUrl(
            Uri.https('wa.me', '/$phone', {'text': text}),
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (opened) return;
        } catch (error) {
          debugPrint('Could not open WhatsApp: $error');
        }
      }
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    } catch (error) {
      debugPrint('Could not share the reminder: $error');
      if (mounted) {
        setState(() => _error = context.l10n.couldNotOpenSharingTryAgain);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.sendReminder,
                    style: AppTypography.serif(
                      fontSize: 20,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close),
                  tooltip: context.l10n.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              minLines: 5,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.message,
                alignLabelWithHint: true,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: context.l10n.openWhatsapp,
              icon: AppIcons.send,
              onPressed: _busy ? null : () => _send(whatsApp: true),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(AppIcons.share),
              label: Text(context.l10n.shareSms),
              onPressed: _busy ? null : () => _send(),
            ),
          ],
        ),
      ),
    );
  }
}
