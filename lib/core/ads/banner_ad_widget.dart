import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../billing/billing_service.dart';
import 'ad_manager.dart';

/// Lightweight banner widget that respects Pro status via BillingService.
/// For most cases, prefer [AdManager.instance.getBannerAdWidget()] which
/// uses the singleton AdManager's own Pro state check.
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    if (isPro) return const SizedBox.shrink();
    return AdManager.instance.getBannerAdWidget();
  }
}
