// This file is kept for backwards-compatibility only.
// All paywall entry points now navigate to PaywallScreen (full-screen).
// Do NOT add new calls to PaywallBottomSheet.show() — use:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));

import 'package:flutter/material.dart';
import '../../paywall/paywall_screen.dart';

@Deprecated('Use PaywallScreen directly via Navigator.push')
class PaywallBottomSheet {
  static Future<void> show(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }
}
