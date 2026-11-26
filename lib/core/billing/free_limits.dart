import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/l10n.dart';

import '../../features/paywall/paywall_screen.dart';
import '../database/db_provider.dart';
import 'billing_service.dart';

/// The free plan's limits, and the one gate every create path goes through
/// (new invoice, duplicate, estimate conversion, client sheet shortcuts).
///
/// The paywall's feature list states these same numbers.
class FreeLimits {
  FreeLimits._();

  /// Invoices a free user can create per calendar month.
  static const int invoicesPerMonth = 10;

  /// Estimates a free user can create per calendar month.
  static const int estimatesPerMonth = 10;

  /// Clients a free user can save.
  static const int savedClients = 10;

  /// True if a new invoice may be created now. Otherwise explains the limit
  /// and offers the paywall.
  static Future<bool> canCreateInvoice(BuildContext context) async {
    if (context.read<BillingService>().isPro) return true;
    final count = await DbProvider.countInvoicesThisMonth();
    if (count < invoicesPerMonth) return true;
    if (!context.mounted) return false;
    await _explain(
      context,
      title: context.l10n.monthlyInvoiceLimitReached,
      message: context.l10n.monthlyInvoiceLimitDetails(invoicesPerMonth),
    );
    return false;
  }

  /// True if a new estimate may be created now.
  static Future<bool> canCreateEstimate(BuildContext context) async {
    if (context.read<BillingService>().isPro) return true;
    final count = await DbProvider.countEstimatesThisMonth();
    if (count < estimatesPerMonth) return true;
    if (!context.mounted) return false;
    await _explain(
      context,
      title: context.l10n.monthlyEstimateLimitReached,
      message: context.l10n.monthlyEstimateLimitDetails(estimatesPerMonth),
    );
    return false;
  }

  /// True if another client may be saved, given [currentCount] saved clients.
  static Future<bool> canSaveClient(BuildContext context, int currentCount) async {
    if (context.read<BillingService>().isPro) return true;
    if (currentCount < savedClients) return true;
    await _explain(
      context,
      title: context.l10n.savedClientLimitReached,
      message: context.l10n.savedClientLimitDetails(savedClients),
    );
    return false;
  }

  static Future<void> _explain(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.seePro)),
        ],
      ),
    );
    if (upgrade == true && context.mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
    }
  }
}
