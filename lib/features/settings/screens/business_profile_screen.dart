import 'dart:io';
import '../../../core/utils/image_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../widgets/signature_pad_sheet.dart';
import '../../../core/theme/app_icons.dart';

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

  /// What was last loaded or saved, to tell whether Back loses edits.
  String _savedSnapshot = '';

  String get _snapshot => [
    for (final c in [
      _nameCtrl,
      _taglineCtrl,
      _addressCtrl,
      _phoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _gstinCtrl,
      _bankNameCtrl,
      _accountCtrl,
      _ifscCtrl,
      _upiCtrl,
      _notesCtrl,
    ])
      c.text.trim(),
    _logoPath ?? '',
    _signaturePath ?? '',
  ].join('\u0000');

  bool get _hasUnsavedChanges => !_isLoading && _snapshot != _savedSnapshot;

  Future<void> _confirmLeave(bool didPop) async {
    if (didPop) return;
    if (_hasUnsavedChanges) {
      final discard = await AppDialog.showConfirmation(
        context: context,
        title: context.l10n.discardChanges,
        message:
            context.l10n.youHaveUnsavedChangesToYourBusinessProfile,
        variant: AppDialogVariant.danger,
        icon: AppIcons.warning,
        confirmLabel: context.l10n.discard,
        cancelLabel: context.l10n.keepEditing,
        isDestructive: true,
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

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
    _notesCtrl.addListener(_onFieldChanged);
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
      _notesCtrl.text =
          prefs.getString('${_prefPrefix}notes') ??
          prefs.getString('default_payment_terms') ??
          '';
      _logoPath = prefs.getString('${_prefPrefix}logo_path');
      _signaturePath = prefs.getString('${_prefPrefix}signature_path');
      _isLoading = false;
    });
    _savedSnapshot = _snapshot;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseFillAllRequiredFields),
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

    _savedSnapshot = _snapshot;
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(AppIcons.checkCircleFilled, color: AppColors.onPrimary, size: 20),
            SizedBox(width: 10),
            Text(
              context.l10n.businessProfileSavedSuccessfully,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.statusPaid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final kept = await ImageStore.keep(picked.path, 'logo');
        if (!mounted) return;
        setState(() => _logoPath = kept);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Settings action failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.couldNotOpenThatImageTryAnotherOne),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _showLogoOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.businessLogo,
                    style: AppTypography.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      AppIcons.close,
                      color: AppColors.slate400,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildMediaOptionCard(
                icon: AppIcons.photoLibrary,
                iconColor: AppColors.squirclePurpleIcon,
                bgColor: AppColors.squirclePurple,
                title: context.l10n.chooseFromGallery,
                subtitle: context.l10n.selectAnExistingPngOrJpegImage,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLogo(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              _buildMediaOptionCard(
                icon: AppIcons.camera,
                iconColor: AppColors.squircleCyanIcon,
                bgColor: AppColors.squircleCyan,
                title: context.l10n.takePhoto,
                subtitle: context.l10n.captureCompanyLogoUsingCamera,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLogo(ImageSource.camera);
                },
              ),
              if (_logoPath != null) ...[
                const SizedBox(height: 8),
                _buildMediaOptionCard(
                  icon: AppIcons.delete,
                  iconColor: AppColors.accentRed,
                  bgColor: AppColors.statusOverdueBg,
                  title: context.l10n.removeLogo,
                  subtitle: context.l10n.clearCurrentLogoImage,
                  isDestructive: true,
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
        final kept = await ImageStore.keep(picked.path, 'signature');
        if (!mounted) return;
        setState(() => _signaturePath = kept);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Settings action failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.couldNotOpenThatSignatureImageTryAnother,
            ),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _showSignatureOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.authorizedSignature,
                    style: AppTypography.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      AppIcons.close,
                      color: AppColors.slate400,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildMediaOptionCard(
                icon: AppIcons.draw,
                iconColor: AppColors.squirclePurpleIcon,
                bgColor: AppColors.squirclePurple,
                title: context.l10n.drawSignatureOnScreen,
                subtitle: context.l10n.signSmoothlyWithYourFingerOrStylus,
                onTap: () {
                  Navigator.pop(ctx);
                  _openSignatureDrawingPad();
                },
              ),
              const SizedBox(height: 8),
              _buildMediaOptionCard(
                icon: AppIcons.image,
                iconColor: AppColors.squircleTealIcon,
                bgColor: AppColors.squircleTeal,
                title: context.l10n.uploadImageFromGallery,
                subtitle: context.l10n.pngWithTransparentBackgroundRecommended,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickSignatureFromGallery();
                },
              ),
              if (_signaturePath != null) ...[
                const SizedBox(height: 8),
                _buildMediaOptionCard(
                  icon: AppIcons.delete,
                  iconColor: AppColors.accentRed,
                  bgColor: AppColors.statusOverdueBg,
                  title: context.l10n.removeSignature,
                  subtitle: context.l10n.clearCurrentSignature,
                  isDestructive: true,
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
      ),
    );
  }

  Widget _buildMediaOptionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.accentRed.withValues(alpha: 0.2)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.accentRed
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
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
    final taxIdLabel = context.l10n.catalogLabel(currencyProvider.taxIdLabel);
    final taxIdHint = context.l10n.catalogLabel(currencyProvider.taxIdHint);
    final bankRoutingLabel = context.l10n.catalogLabel(currencyProvider.bankRoutingLabel);
    final bankRoutingHint = context.l10n.catalogLabel(currencyProvider.bankRoutingHint);
    final bankAccountLabel = context.l10n.catalogLabel(currencyProvider.bankAccountLabel);
    final bankAccountHint = context.l10n.catalogLabel(currencyProvider.bankAccountHint);
    final bankNameHint = context.l10n.catalogLabel(currencyProvider.bankNameHint);
    final digitalPaymentLabel = context.l10n.catalogLabel(currencyProvider.digitalPaymentLabel);
    final digitalPaymentHint = context.l10n.catalogLabel(currencyProvider.digitalPaymentHint);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final strength = _calculateProfileStrength();
    final percentage = (strength * 100).round();

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) => _confirmLeave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ),
          leading: IconButton(
            icon: Icon(AppIcons.arrowBack, color: AppColors.ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(context.l10n.businessProfile),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.ink,
                          ),
                        ),
                      )
                    : Text(
                        context.l10n.save,
                        style: GoogleFonts.inter(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
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
                title: context.l10n.brandingIdentity,
                icon: AppIcons.sparkle,
                iconColor: AppColors.badgeViolet,
                iconBg: AppColors.badgeViolet.withValues(alpha: 0.12),
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
                              label: context.l10n.companyLogo,
                              subtitle: _logoPath != null
                                  ? context.l10n.tapToChange
                                  : context.l10n.uploadLogo,
                              icon: AppIcons.addPhoto,
                              imagePath: _logoPath,
                              onTap: _showLogoOptions,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Signature Box
                          Expanded(
                            child: _buildMediaTile(
                              label: context.l10n.authorizedSignature,
                              subtitle: _signaturePath != null
                                  ? context.l10n.tapToChange
                                  : context.l10n.drawOrUpload,
                              icon: AppIcons.draw,
                              imagePath: _signaturePath,
                              onTap: _showSignatureOptions,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: context.l10n.businessCompanyName,
                        hint: context.l10n.eGAcmeInnovationsLlc,
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icon(
                          AppIcons.storefront,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? context.l10n.businessNameIsRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: context.l10n.taglineOrIndustryOptional,
                        hint: context.l10n.eGCreativeStudioDigitalAgency,
                        controller: _taglineCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        prefixIcon: Icon(
                          AppIcons.badge,
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
                title: context.l10n.contactLocation,
                icon: AppIcons.contactCard,
                iconColor: AppColors.squircleCyanIcon,
                iconBg: AppColors.squircleCyan,
              ),
              _buildCardGroup([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomTextField(
                        label: context.l10n.businessEmail,
                        hint: 'contact@mycompany.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          AppIcons.mail,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: context.l10n.phoneNumber,
                        hint: '+1 (555) 019-2834',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(
                          AppIcons.phone,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: context.l10n.websitePortfolio,
                        hint: 'https://mycompany.com',
                        controller: _websiteCtrl,
                        keyboardType: TextInputType.url,
                        prefixIcon: Icon(
                          AppIcons.globe,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: context.l10n.registeredBusinessAddress,
                        hint: context.l10n.suite400100MainStreetCityStateZip,
                        controller: _addressCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 36),
                          child: Icon(
                            AppIcons.location,
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
                title: context.l10n.taxLegalRegistration,
                icon: AppIcons.gavel,
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
                        prefixIcon: Icon(
                          AppIcons.receipt,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            AppIcons.info,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.l10n.thisWillBeDisplayedOnAllGeneratedPdfs(taxIdLabel, context.l10n.catalogLabel(currencyProvider.countryName)),
                              style: TextStyle(
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
                title: context.l10n.bankPaymentDetails,
                icon: AppIcons.bank,
                iconColor: AppColors.ink,
                iconBg: AppColors.surfaceCard,
                trailing: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => CurrencyPickerSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.hairline.withValues(
                          alpha: 0.2,
                        ),
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
                          '${currencyProvider.currencyCode} (${context.l10n.catalogLabel(currencyProvider.countryName)})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          AppIcons.caretDown,
                          size: 16,
                          color: AppColors.ink,
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              currencyProvider.flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.paymentFieldsRoutingFormatMatchStandards(context.l10n.catalogLabel(currencyProvider.countryName), currencyProvider.currencyCode),
                                style: TextStyle(
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
                        label: context.l10n.bankName,
                        hint: bankNameHint,
                        controller: _bankNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icon(
                          AppIcons.bank,
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
                        prefixIcon: Icon(
                          AppIcons.numbers,
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
                        prefixIcon: Icon(
                          AppIcons.pin,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Digital Payment / UPI (localized label & hint)
                      CustomTextField(
                        label: context.l10n.optionalFieldTitle(digitalPaymentLabel),
                        hint: digitalPaymentHint,
                        controller: _upiCtrl,
                        keyboardType: TextInputType.text,
                        prefixIcon: Icon(
                          AppIcons.qrCode,
                          color: AppColors.slate500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Default Payment Terms & Notes
                      CustomTextField(
                        label: context.l10n.defaultPaymentNotesTerms,
                        hint:
                            context.l10n.eGNet15PaymentIsDueWithin,
                        controller: _notesCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(
                            AppIcons.assignment,
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
            color: AppColors.canvas,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: PrimaryButton(
              label: context.l10n.saveBusinessProfile,
              isLoading: _isSaving,
              icon: AppIcons.checkCircle,
              onPressed: _saveProfile,
            ),
          ),
        ),
      ),
    );
  }

  // 1. Live Hero Preview Card (Cal.com Executive Identity Card)
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
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16), // rounded.xl
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar / Logo Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _logoPath != null ? Colors.white : AppColors.canvas, // paper
                    borderRadius: BorderRadius.circular(12), // rounded.lg
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _logoPath != null && File(_logoPath!).existsSync()
                        ? Image.file(File(_logoPath!), fit: BoxFit.contain)
                        : Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name.substring(0, 1).toUpperCase()
                                  : 'B',
                              style: AppTypography.serif(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
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
                              name.isNotEmpty ? name : context.l10n.yourBusinessName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: name.isNotEmpty
                                    ? AppColors.ink
                                    : AppColors.mutedSoft,
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
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyProvider.flag,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currencyProvider.currencyCode,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tagline.isNotEmpty
                            ? tagline
                            : context.l10n.setYourBusinessIdentity,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: tagline.isNotEmpty
                              ? AppColors.muted
                              : AppColors.mutedSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (taxId.isNotEmpty ||
                          (_signaturePath != null &&
                              File(_signaturePath!).existsSync())) ...[
                        const SizedBox(height: 8),
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
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Text(
                                  '${context.l10n.catalogLabel(currencyProvider.taxIdLabel)}: $taxId',
                                  style: AppTypography.monoCode(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            if (_signaturePath != null &&
                                File(_signaturePath!).existsSync())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.statusPaidBg,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: AppColors.statusPaid.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.verified,
                                      size: 11,
                                      color: AppColors.statusPaid,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      context.l10n.signed,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                if (email.isNotEmpty || phone.isNotEmpty) ...[
                  Row(
                    children: [
                      if (email.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.mail,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.body,
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
                              Icon(
                                AppIcons.phone,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.body,
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
                              Icon(
                                AppIcons.location,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.body,
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
                              Icon(
                                AppIcons.globe,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  website,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.body,
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
                              Icon(
                                AppIcons.bank,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  bankName.isNotEmpty && account.isNotEmpty
                                      ? '$bankName • $account'
                                      : (bankName.isNotEmpty
                                            ? bankName
                                            : account),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
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
                              Icon(
                                AppIcons.qrCode,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${context.l10n.catalogLabel(currencyProvider.digitalPaymentLabel)}: $upi',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.hairline),
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
                                Text(
                                  context.l10n.profileReadiness,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: AppTypography.monoCode(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: percentage >= 80
                                        ? AppColors.statusPaid
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9999),
                              child: LinearProgressIndicator(
                                value: strength,
                                minHeight: 4,
                                backgroundColor: AppColors.hairline,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage >= 80
                                      ? AppColors.statusPaid
                                      : AppColors.ink,
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
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              // A logo or signature is shown on paper, as it prints, so dark
              // ink stays visible in dark mode.
              color: hasImage ? Colors.white : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12), // rounded.lg
              border: Border.all(
                color: hasImage ? AppColors.ink : AppColors.hairline,
                width: hasImage ? 1.5 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                              color: AppColors.canvas,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Icon(
                              AppIcons.edit,
                              size: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Icon(icon, size: 20, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
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
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
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
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12), // rounded.lg
        border: Border.all(color: AppColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
