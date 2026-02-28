import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/primary_button.dart';
import '../widgets/paywall_bottom_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  String? _logoPath;
  bool _isSaving = false;

  static const String _prefPrefix = 'biz_';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('${_prefPrefix}name') ?? '';
      _addressCtrl.text = prefs.getString('${_prefPrefix}address') ?? '';
      _phoneCtrl.text = prefs.getString('${_prefPrefix}phone') ?? '';
      _emailCtrl.text = prefs.getString('${_prefPrefix}email') ?? '';
      _gstinCtrl.text = prefs.getString('${_prefPrefix}gstin') ?? '';
      _bankNameCtrl.text = prefs.getString('${_prefPrefix}bank_name') ?? '';
      _accountCtrl.text = prefs.getString('${_prefPrefix}account') ?? '';
      _ifscCtrl.text = prefs.getString('${_prefPrefix}ifsc') ?? '';
      _logoPath = prefs.getString('${_prefPrefix}logo_path');
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefPrefix}name', _nameCtrl.text.trim());
    await prefs.setString('${_prefPrefix}address', _addressCtrl.text.trim());
    await prefs.setString('${_prefPrefix}phone', _phoneCtrl.text.trim());
    await prefs.setString('${_prefPrefix}email', _emailCtrl.text.trim());
    await prefs.setString('${_prefPrefix}gstin', _gstinCtrl.text.trim());
    await prefs.setString('${_prefPrefix}bank_name', _bankNameCtrl.text.trim());
    await prefs.setString('${_prefPrefix}account', _accountCtrl.text.trim());
    await prefs.setString('${_prefPrefix}ifsc', _ifscCtrl.text.trim());
    if (_logoPath != null) {
      await prefs.setString('${_prefPrefix}logo_path', _logoPath!);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile saved!'),
          backgroundColor: AppColors.statusPaid,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickLogo() async {
    final isPro = context.read<BillingService>().isPro;
    if (!isPro) {
      PaywallBottomSheet.show(context);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo Section
            _buildSectionCard(
              title: 'Business Logo',
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _logoPath != null && File(_logoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_logoPath!),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPro ? Icons.add_photo_alternate_outlined : Icons.lock_outline,
                                size: 36,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPro ? 'Tap to upload logo' : 'Pro feature – Unlock to add logo',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (!isPro) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => PaywallBottomSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.proGoldLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.proGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: AppColors.proGold, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Upgrade to Pro to add your logo',
                              style: TextStyle(fontSize: 12, color: AppColors.slate700),
                            ),
                          ),
                          const Text(
                            'Unlock →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.proGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Business Info
            _buildSectionCard(
              title: 'Business Information',
              children: [
                CustomTextField(
                  label: 'Business Name *',
                  hint: 'Your Company Name',
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Address',
                  hint: '123 Main St, City, State - 400001',
                  controller: _addressCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Phone',
                  hint: '+91 98765 43210',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Email',
                  hint: 'business@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'GSTIN',
                  hint: '22AAAAA0000A1Z5',
                  controller: _gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bank Details
            _buildSectionCard(
              title: 'Bank Details (for PDF)',
              children: [
                CustomTextField(
                  label: 'Bank Name',
                  hint: 'State Bank of India',
                  controller: _bankNameCtrl,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Account Number',
                  hint: '1234567890',
                  controller: _accountCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'IFSC Code',
                  hint: 'SBIN0001234',
                  controller: _ifscCtrl,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Save Profile',
              isLoading: _isSaving,
              onPressed: _saveProfile,
              icon: Icons.save_outlined,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
