import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/primary_button.dart';
import '../widgets/signature_pad_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _logoPath;
  String? _signaturePath;
  bool _isLoading = true;
  bool _isSaving = false;

  static const String _prefPrefix = 'biz_';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Listen to text changes to update the live preview card in real-time
    _nameCtrl.addListener(_onFieldChanged);
    _taglineCtrl.addListener(_onFieldChanged);
    _emailCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
    _addressCtrl.addListener(_onFieldChanged);
    _gstinCtrl.addListener(_onFieldChanged);
    _websiteCtrl.addListener(_onFieldChanged);
    _bankNameCtrl.addListener(_onFieldChanged);
    _accountCtrl.addListener(_onFieldChanged);
    _ifscCtrl.addListener(_onFieldChanged);
    _upiCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _nameCtrl.text = prefs.getString('${_prefPrefix}name') ?? '';
      _taglineCtrl.text = prefs.getString('${_prefPrefix}tagline') ?? '';
      _addressCtrl.text = prefs.getString('${_prefPrefix}address') ?? '';
      _phoneCtrl.text = prefs.getString('${_prefPrefix}phone') ?? '';
      _emailCtrl.text = prefs.getString('${_prefPrefix}email') ?? '';
      _websiteCtrl.text = prefs.getString('${_prefPrefix}website') ?? '';
      _gstinCtrl.text = prefs.getString('${_prefPrefix}gstin') ?? '';
      _bankNameCtrl.text = prefs.getString('${_prefPrefix}bank_name') ?? '';
      _accountCtrl.text = prefs.getString('${_prefPrefix}account') ?? '';
      _ifscCtrl.text = prefs.getString('${_prefPrefix}ifsc') ?? '';
      _upiCtrl.text = prefs.getString('${_prefPrefix}upi') ?? '';
      _notesCtrl.text = prefs.getString('${_prefPrefix}notes') ??
          prefs.getString('default_payment_terms') ??
          '';
      _logoPath = prefs.getString('${_prefPrefix}logo_path');
      _signaturePath = prefs.getString('${_prefPrefix}signature_path');
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefPrefix}name', _nameCtrl.text.trim());
    await prefs.setString('${_prefPrefix}tagline', _taglineCtrl.text.trim());
    await prefs.setString('${_prefPrefix}address', _addressCtrl.text.trim());
    await prefs.setString('${_prefPrefix}phone', _phoneCtrl.text.trim());
    await prefs.setString('${_prefPrefix}email', _emailCtrl.text.trim());
    await prefs.setString('${_prefPrefix}website', _websiteCtrl.text.trim());
    await prefs.setString('${_prefPrefix}gstin', _gstinCtrl.text.trim());
    await prefs.setString('${_prefPrefix}bank_name', _bankNameCtrl.text.trim());
    await prefs.setString('${_prefPrefix}account', _accountCtrl.text.trim());
    await prefs.setString('${_prefPrefix}ifsc', _ifscCtrl.text.trim());
    await prefs.setString('${_prefPrefix}upi', _upiCtrl.text.trim());
    await prefs.setString('${_prefPrefix}notes', _notesCtrl.text.trim());

    if (_logoPath != null && _logoPath!.isNotEmpty) {
      await prefs.setString('${_prefPrefix}logo_path', _logoPath!);
    } else {
      await prefs.remove('${_prefPrefix}logo_path');
    }

    if (_signaturePath != null && _signaturePath!.isNotEmpty) {
      await prefs.setString('${_prefPrefix}signature_path', _signaturePath!);
    } else {
      await prefs.remove('${_prefPrefix}signature_path');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Business profile saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.statusPaid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _logoPath = picked.path);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load image: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _showLogoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Business Logo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.squirclePurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.squirclePurpleIcon,
                  size: 20,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                'Select existing PNG or JPEG file',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.squircleCyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.squircleCyanIcon,
                  size: 20,
                ),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                'Capture company logo using camera',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
            if (_logoPath != null) ...[
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusOverdueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.accentRed,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Remove Logo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.accentRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _logoPath = null);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSignatureDrawingPad() async {
    final signaturePath = await SignaturePadSheet.show(context);
    if (signaturePath != null && mounted) {
      setState(() => _signaturePath = signaturePath);
    }
  }

  Future<void> _pickSignatureFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _signaturePath = picked.path);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load signature: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _showSignatureOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Authorized Signature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.squirclePurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.draw_rounded,
                  color: AppColors.squirclePurpleIcon,
                  size: 20,
                ),
              ),
              title: const Text(
                'Draw Signature on Screen',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                'Sign with your finger or stylus pen',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openSignatureDrawingPad();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.squircleTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.squircleTealIcon,
                  size: 20,
                ),
              ),
              title: const Text(
                'Upload Image from Gallery',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                'PNG with transparent background recommended',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickSignatureFromGallery();
              },
            ),
            if (_signaturePath != null) ...[
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusOverdueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.accentRed,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Remove Signature',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.accentRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _signaturePath = null);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _calculateProfileStrength() {
    double score = 0;
    if (_nameCtrl.text.trim().isNotEmpty) score += 0.25;
    if (_emailCtrl.text.trim().isNotEmpty) score += 0.15;
    if (_phoneCtrl.text.trim().isNotEmpty) score += 0.15;
    if (_addressCtrl.text.trim().isNotEmpty) score += 0.15;
    if (_gstinCtrl.text.trim().isNotEmpty) score += 0.10;
    if (_logoPath != null && _logoPath!.isNotEmpty) score += 0.10;
    if (_signaturePath != null && _signaturePath!.isNotEmpty) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _taglineCtrl.removeListener(_onFieldChanged);
    _emailCtrl.removeListener(_onFieldChanged);
    _phoneCtrl.removeListener(_onFieldChanged);
    _addressCtrl.removeListener(_onFieldChanged);
    _gstinCtrl.removeListener(_onFieldChanged);
    _websiteCtrl.removeListener(_onFieldChanged);
    _bankNameCtrl.removeListener(_onFieldChanged);
    _accountCtrl.removeListener(_onFieldChanged);
    _ifscCtrl.removeListener(_onFieldChanged);
    _upiCtrl.removeListener(_onFieldChanged);

    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _gstinCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final taxIdLabel = currencyProvider.taxIdLabel;
    final taxIdHint = currencyProvider.taxIdHint;
    final bankRoutingLabel = currencyProvider.bankRoutingLabel;
    final bankRoutingHint = currencyProvider.bankRoutingHint;
    final bankAccountLabel = currencyProvider.bankAccountLabel;
    final bankAccountHint = currencyProvider.bankAccountHint;
    final bankNameHint = currencyProvider.bankNameHint;
    final digitalPaymentLabel = currencyProvider.digitalPaymentLabel;
    final digitalPaymentHint = currencyProvider.digitalPaymentHint;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final strength = _calculateProfileStrength();
    final percentage = (strength * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Business Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // 1. Live Hero Business Card Preview
            _buildLivePreviewCard(
              currencyProvider: currencyProvider,
              strength: strength,
              percentage: percentage,
            ),
            const SizedBox(height: 20),

            // 2. Branding & Media Section (Logo + Signature)
            _buildSectionHeader(
              title: 'Branding & Identity',
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.squirclePurpleIcon,
              iconBg: AppColors.squirclePurple,
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business Logo Box
                        Expanded(
                          child: _buildMediaTile(
                            label: 'Company Logo',
                            subtitle: _logoPath != null
                                ? 'Tap to change'
                                : 'Upload logo',
                            icon: Icons.add_photo_alternate_outlined,
                            imagePath: _logoPath,
                            onTap: _showLogoOptions,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Signature Box
                        Expanded(
                          child: _buildMediaTile(
                            label: 'Authorized Signature',
                            subtitle: _signaturePath != null
                                ? 'Tap to change'
                                : 'Draw or upload',
                            icon: Icons.draw_outlined,
                            imagePath: _signaturePath,
                            onTap: _showSignatureOptions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Business / Company Name *',
                      hint: 'e.g. Acme Innovations LLC',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Business name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Tagline or Industry (Optional)',
                      hint: 'e.g. Creative Studio & Digital Agency',
                      controller: _taglineCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // 3. Contact & Location Section
            _buildSectionHeader(
              title: 'Contact & Location',
              icon: Icons.contact_mail_rounded,
              iconColor: AppColors.squircleCyanIcon,
              iconBg: AppColors.squircleCyan,
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Business Email',
                      hint: 'contact@mycompany.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Phone Number',
                      hint: '+1 (555) 019-2834',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Website / Portfolio',
                      hint: 'https://mycompany.com',
                      controller: _websiteCtrl,
                      keyboardType: TextInputType.url,
                      prefixIcon: const Icon(
                        Icons.language_rounded,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Registered Business Address',
                      hint: 'Suite 400, 100 Main Street, City, State, ZIP',
                      controller: _addressCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 36),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // 4. Tax & Legal Section
            _buildSectionHeader(
              title: 'Tax & Legal Registration',
              icon: Icons.gavel_rounded,
              iconColor: AppColors.squircleOrangeIcon,
              iconBg: AppColors.squircleOrange,
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: taxIdLabel,
                      hint: taxIdHint,
                      controller: _gstinCtrl,
                      textCapitalization: TextCapitalization.characters,
                      prefixIcon: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'This $taxIdLabel will be displayed on all generated PDFs and estimates for ${currencyProvider.countryName}.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // 5. Bank & Payment Methods Section
            _buildSectionHeader(
              title: 'Bank & Payment Details',
              icon: Icons.account_balance_rounded,
              iconColor: AppColors.squircleGreenIcon,
              iconBg: AppColors.squircleGreen,
              trailing: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => CurrencyPickerSheet.show(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.squircleGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          AppColors.squircleGreenIcon.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyProvider.flag,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currencyProvider.currencyCode} (${currencyProvider.countryName})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.squircleGreenIcon,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: AppColors.squircleGreenIcon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildCardGroup([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country specific banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Text(currencyProvider.flag,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment fields & routing format match ${currencyProvider.countryName} (${currencyProvider.currencyCode}) standards.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bank Name
                    CustomTextField(
                      label: 'Bank Name',
                      hint: bankNameHint,
                      controller: _bankNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Number (localized label & hint)
                    CustomTextField(
                      label: bankAccountLabel,
                      hint: bankAccountHint,
                      controller: _accountCtrl,
                      keyboardType: TextInputType.text,
                      prefixIcon: const Icon(
                        Icons.numbers_rounded,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Routing / IFSC / Sort code / Transit / BSB (localized label & hint)
                    CustomTextField(
                      label: bankRoutingLabel,
                      hint: bankRoutingHint,
                      controller: _ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      prefixIcon: const Icon(
                        Icons.pin_outlined,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Digital Payment / UPI (localized label & hint)
                    CustomTextField(
                      label: '$digitalPaymentLabel (Optional)',
                      hint: digitalPaymentHint,
                      controller: _upiCtrl,
                      keyboardType: TextInputType.text,
                      prefixIcon: const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.slate500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Default Payment Terms & Notes
                    CustomTextField(
                      label: 'Default Payment Notes & Terms',
                      hint:
                          'e.g. Net 15. Payment is due within 15 days of invoice date.',
                      controller: _notesCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Save Business Profile',
            isLoading: _isSaving,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _saveProfile,
          ),
        ),
      ),
    );
  }

  // 1. Live Hero Preview Card
  Widget _buildLivePreviewCard({
    required CurrencyProvider currencyProvider,
    required double strength,
    required int percentage,
  }) {
    final name = _nameCtrl.text.trim();
    final tagline = _taglineCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final taxId = _gstinCtrl.text.trim();
    final website = _websiteCtrl.text.trim();
    final bankName = _bankNameCtrl.text.trim();
    final account = _accountCtrl.text.trim();
    final upi = _upiCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryLight.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Logo
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(37, 99, 235, 0.12),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _logoPath != null && File(_logoPath!).existsSync()
                        ? Image.file(
                            File(_logoPath!),
                            fit: BoxFit.contain,
                          )
                        : Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name.substring(0, 1).toUpperCase()
                                  : 'B',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Tagline & Tax Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isNotEmpty ? name : 'Your Business Name',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: name.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.slate400,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Currency Country Flag Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(currencyProvider.flag,
                                    style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                Text(
                                  currencyProvider.currencyCode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline.isNotEmpty
                            ? tagline
                            : 'Set your business identity',
                        style: TextStyle(
                          fontSize: 12,
                          color: tagline.isNotEmpty
                              ? AppColors.textSecondary
                              : AppColors.slate400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (taxId.isNotEmpty ||
                          (_signaturePath != null &&
                              File(_signaturePath!).existsSync())) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (taxId.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  '${currencyProvider.taxIdLabel}: $taxId',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            if (_signaturePath != null &&
                                File(_signaturePath!).existsSync())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.statusPaidBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.statusPaid
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 11,
                                      color: AppColors.statusPaid,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Signed',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.statusPaid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact & Bank Details Sub-Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                if (email.isNotEmpty || phone.isNotEmpty) ...[
                  Row(
                    children: [
                      if (email.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (address.isNotEmpty || website.isNotEmpty) ...[
                  Row(
                    children: [
                      if (address.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (website.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language_rounded,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  website,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (bankName.isNotEmpty ||
                    account.isNotEmpty ||
                    upi.isNotEmpty) ...[
                  Row(
                    children: [
                      if (bankName.isNotEmpty || account.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_outlined,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  bankName.isNotEmpty && account.isNotEmpty
                                      ? '$bankName • $account'
                                      : (bankName.isNotEmpty
                                          ? bankName
                                          : account),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (upi.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 14,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${currencyProvider.digitalPaymentLabel}: $upi',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Completeness Progress Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Profile Readiness',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate600,
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: percentage >= 80
                                        ? AppColors.statusPaid
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength,
                                minHeight: 5,
                                backgroundColor: AppColors.slate200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage >= 80
                                      ? AppColors.statusPaid
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Media Tile (Logo / Signature)
  Widget _buildMediaTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.cardBorder,
                width: hasImage ? 1.5 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: hasImage
                  ? Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Icon(icon, size: 22, color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // Section Header with optional trailing widget
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  // Card Group Container
  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
