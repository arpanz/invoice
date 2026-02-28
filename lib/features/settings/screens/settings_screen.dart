import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/paywall_bottom_sheet.dart';
import 'business_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'INR';
  double _defaultTaxRate = 18.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('default_currency') ?? 'INR';
      _defaultTaxRate = prefs.getDouble('default_tax_rate') ?? 18.0;
    });
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_currency', currency);
    setState(() => _currency = currency);
  }

  Future<void> _saveTaxRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_tax_rate', rate);
    setState(() => _defaultTaxRate = rate);
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pro Upsell Card (only if not pro)
          if (!billing.isPro) ...[
            _buildProUpsellCard(context),
            const SizedBox(height: 16),
          ] else ...[
            _buildProBadgeCard(),
            const SizedBox(height: 16),
          ],

          // Business Profile
          _buildSectionHeader('Workspace'),
          _buildListTile(
            icon: Icons.business_outlined,
            title: 'Business Profile',
            subtitle: 'Name, address, bank details, logo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences
          _buildSectionHeader('Preferences'),
          _buildCurrencyTile(),
          const Divider(height: 1, indent: 56),
          _buildTaxRateTile(),
          const SizedBox(height: 16),

          // Support
          _buildSectionHeader('Support'),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Rate Invoice Maker Pro',
            subtitle: 'Love the app? Leave us a 5-star review!',
            onTap: _showRateDialog,
            trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.slate400),
          ),
          const Divider(height: 1, indent: 56),
          _buildListTile(
            icon: Icons.mail_outline,
            title: 'Contact Developer',
            subtitle: 'support@invoicemakerpro.app',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // App Info
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Invoice Maker Pro',
            subtitle: 'Version 1.0.0 • 100% Offline & Private',
            onTap: null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProUpsellCard(BuildContext context) {
    return GestureDetector(
      onTap: () => PaywallBottomSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.proGold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock Pro Workspace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remove watermarks & ads. Add your logo.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.proGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '\$4.99',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPaidBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusPaid.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.statusPaid, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pro Workspace Active',
                style: TextStyle(
                  color: AppColors.statusPaid,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Watermarks removed • Ads disabled • Logo enabled',
                style: TextStyle(color: AppColors.slate600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.slate600),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.slate400) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCurrencyTile() {
    final currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED'];
    final symbols = {'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'AED': 'AED'};

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.currency_exchange, size: 18, color: AppColors.slate600),
        ),
        title: const Text('Default Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('${symbols[_currency]} $_currency', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: DropdownButton<String>(
          value: _currency,
          underline: const SizedBox(),
          items: currencies.map((c) => DropdownMenuItem(
            value: c,
            child: Text('${symbols[c]} $c'),
          )).toList(),
          onChanged: (v) => v != null ? _saveCurrency(v) : null,
        ),
      ),
    );
  }

  Widget _buildTaxRateTile() {
    final rates = [0.0, 5.0, 12.0, 18.0, 28.0];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.percent, size: 18, color: AppColors.slate600),
        ),
        title: const Text('Default GST Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('${_defaultTaxRate.toStringAsFixed(0)}% applied to new invoices', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: DropdownButton<double>(
          value: _defaultTaxRate,
          underline: const SizedBox(),
          items: rates.map((r) => DropdownMenuItem(
            value: r,
            child: Text('${r.toStringAsFixed(0)}%'),
          )).toList(),
          onChanged: (v) => v != null ? _saveTaxRate(v) : null,
        ),
      ),
    );
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enjoying Invoice Maker Pro?'),
        content: const Text(
          'Your 5-star review helps other business owners discover the app and keeps it free!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Launch store review URL
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Rate Now ⭐'),
          ),
        ],
      ),
    );
  }
}
