import 'package:flutter/material.dart';
import '../../../core/models/currency_model.dart';
import '../../../core/utils/document_totals.dart';
import '../../../core/utils/number_text.dart';
import '../../../shared_widgets/app_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/billing/free_limits.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../clients/models/client_model.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../invoices/models/document_custom_field.dart';
import '../../invoices/widgets/custom_fields_card.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/invoice_customization_config.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/services/invoice_render_service.dart';
import '../../invoices/widgets/pdf_theme_picker_sheet.dart';
import '../../items/screens/item_picker_sheet.dart';
import '../models/estimate_model.dart';
import 'estimate_preview_screen.dart';
import '../../../core/theme/app_icons.dart';

/// The note a new estimate starts with. Not carried into an invoice.
const String defaultEstimateNote = 'This estimate is valid for 30 days. Contact us to accept.';

class CreateEstimateScreen extends StatefulWidget {
  final EstimateModel? existingEstimate;

  const CreateEstimateScreen({super.key, this.existingEstimate});

  /// Kept for existing callers; see [FreeLimits.canCreateEstimate].
  static Future<bool> canCreateNewEstimate(BuildContext context) => FreeLimits.canCreateEstimate(context);

  @override
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  final _scrollController = ScrollController();

  // Estimate Number & Dates
  final _estimateNumberCtrl = TextEditingController();
  DateTime _estimateDate = DateTime.now();
  DateTime? _expiryDate;

  // Business Profile
  String? _bizName;

  // Client Details
  ClientModel? _selectedClient;

  /// The client name the estimate was loaded with. Saving under a different
  /// name means a different client, so the old link and contact details
  /// (which this editor cannot show) are dropped. Decided at save, so a typo
  /// fixed along the way loses nothing.
  String? _loadedClientName;

  bool get _clientRenamed {
    final loaded = _loadedClientName;
    return _selectedClient == null &&
        loaded != null &&
        _clientNameCtrl.text.trim().toLowerCase() != loaded.trim().toLowerCase();
  }
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientGstinCtrl = TextEditingController();

  // Line Items
  final List<LineItemModel> _items = [];

  // Financial Calculations
  bool _hasDiscount = false;
  DiscountType _discountType = DiscountType.percentage;
  final _discountCtrl = TextEditingController(text: '0');

  bool _hasTax = false;
  bool _useIGST = false;
  final _sgstCtrl = TextEditingController(text: '9');
  final _cgstCtrl = TextEditingController(text: '9');
  final _igstCtrl = TextEditingController(text: '18');

  // Notes & Theme
  String _currency = 'INR';
  List<DocumentCustomField> _customFields = const [];
  List<String> _recentFieldLabels = const [];
  final _notesCtrl = TextEditingController(
    text: defaultEstimateNote,
  );
  PdfTheme _selectedTheme = PdfTheme.defaultTheme;
  PdfThemeId? _initialThemeId;
  InvoiceCustomizationConfig? _customDesign;
  EstimateStatus _status = EstimateStatus.pending;

  String? _activeEstimateId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _estimateNumberCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientGstinCtrl.dispose();
    _discountCtrl.dispose();
    _sgstCtrl.dispose();
    _cgstCtrl.dispose();
    _igstCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final currencyProvider = context.read<CurrencyProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _recentFieldLabels = DocumentFieldPreferences.recent(prefs);
    _customFields = widget.existingEstimate?.customFields ?? const [];


    _bizName = prefs.getString('biz_name');

    final savedThemeId = (widget.existingEstimate != null
            ? prefs.getString('estimate_theme_${widget.existingEstimate!.id}')
            : null) ??
        prefs.getString('default_pdf_theme');
    if (savedThemeId != null) {
      _selectedTheme = PdfTheme.fromId(savedThemeId);
    }
    if (widget.existingEstimate == null) {
      // A new estimate inherits the custom default design in full, not just
      // its template, until a template is picked in this editor.
      final inherited = await InvoiceRenderService.defaultCustomDesign();
      if (inherited != null) {
        _customDesign = inherited;
        _selectedTheme = PdfTheme.fromId(inherited.themeId.value);
      }
    }
    _initialThemeId = _selectedTheme.id;

    if (widget.existingEstimate != null) {
      final e = widget.existingEstimate!;
      _activeEstimateId = e.id;
      _estimateNumberCtrl.text = e.estimateNumber;
      _estimateDate = e.estimateDate;
      _expiryDate = e.expiryDate;
      _clientNameCtrl.text = e.clientName;
      _loadedClientName = e.clientName;
      _clientEmailCtrl.text = e.clientEmail ?? '';
      _clientPhoneCtrl.text = e.clientPhone ?? '';
      _clientAddressCtrl.text = e.clientAddress ?? '';
      _clientGstinCtrl.text = e.clientGstin ?? '';
      _items.addAll(e.lineItems);

      _hasDiscount = e.discountType != DiscountType.none && e.discountValue > 0;
      _discountType = e.discountType;
      _discountCtrl.text = NumberText.trim(e.discountValue);

      _hasTax = (e.sgstRate + e.cgstRate + e.igstRate) > 0;
      final isDual = SupportedCurrencies.getByCode(e.currency)?.defaultTax.isDualTax ?? false;
      // A single-tax currency always uses the single rate field.
      _useIGST = e.igstRate > 0 || !isDual;
      if (_hasTax) {
        _sgstCtrl.text = NumberText.trim(e.sgstRate);
        _cgstCtrl.text = NumberText.trim(e.cgstRate);
        _igstCtrl.text = NumberText.trim(e.igstRate);
      } else {
        // Saved without tax: pre-fill the default so switching tax on works.
        final rate = currencyProvider.defaultTax.rate;
        _sgstCtrl.text = NumberText.trim(rate / 2);
        _cgstCtrl.text = NumberText.trim(rate / 2);
        _igstCtrl.text = NumberText.trim(rate);
      }

      _notesCtrl.text = e.notes ?? '';
      _currency = e.currency;
      _status = e.status;
    } else {
      _activeEstimateId = const Uuid().v4();
      final nextNum = await DbProvider.getNextEstimateNumber();
      _estimateNumberCtrl.text = nextNum;
      _currency = currencyProvider.currencyCode;
      _expiryDate = DateTime.now().add(const Duration(days: 30));

      final taxCfg = currencyProvider.defaultTax;
      if (taxCfg.isDualTax) {
        final half = taxCfg.rate / 2;
        _sgstCtrl.text = NumberText.trim(half);
        _cgstCtrl.text = NumberText.trim(half);
        _igstCtrl.text = NumberText.trim(taxCfg.rate);
      } else {
        _igstCtrl.text = NumberText.trim(taxCfg.rate);
        _useIGST = true;
      }
    }

    _initialSignature = _editSignature;
    if (mounted) setState(() {});
  }

  DocumentTotals get _totals => DocumentTotals.forCurrency(
        currencyCode: _currency,
        lines: _items,
        discountType: _hasDiscount ? _discountType : DiscountType.none,
        discountValue: _hasDiscount ? NumberText.parse(_discountCtrl.text) : 0,
        sgstRate: _hasTax && !_useIGST ? NumberText.parse(_sgstCtrl.text) : 0,
        cgstRate: _hasTax && !_useIGST ? NumberText.parse(_cgstCtrl.text) : 0,
        igstRate: _hasTax && _useIGST ? NumberText.parse(_igstCtrl.text) : 0,
      );

  double get _subtotal => _totals.subtotal;
  double get _discountAmount => _totals.discountAmount;
  double get _taxAmount => _totals.taxAmount;
  double get _grandTotal => _totals.grandTotal;

  EstimateModel _buildEstimateModel() {
    final now = DateTime.now();
    final renamed = _clientRenamed;
    return EstimateModel(
      id: _activeEstimateId ?? const Uuid().v4(),
      estimateNumber: _estimateNumberCtrl.text.trim(),
      clientId: _selectedClient?.id ?? (renamed ? null : widget.existingEstimate?.clientId),
      clientName: _clientNameCtrl.text.trim(),
      clientEmail: renamed || _clientEmailCtrl.text.trim().isEmpty
          ? null
          : _clientEmailCtrl.text.trim(),
      clientPhone: renamed || _clientPhoneCtrl.text.trim().isEmpty
          ? null
          : _clientPhoneCtrl.text.trim(),
      clientAddress: renamed || _clientAddressCtrl.text.trim().isEmpty
          ? null
          : _clientAddressCtrl.text.trim(),
      clientGstin: renamed || _clientGstinCtrl.text.trim().isEmpty
          ? null
          : _clientGstinCtrl.text.trim(),
      estimateDate: _estimateDate,
      expiryDate: _expiryDate,
      subtotal: _subtotal,
      discountType: _hasDiscount ? _discountType : DiscountType.none,
      discountValue: _hasDiscount ? NumberText.parse(_discountCtrl.text) : 0,
      discountAmount: _discountAmount,
      sgstRate: _hasTax && !_useIGST ? NumberText.parse(_sgstCtrl.text) : 0,
      cgstRate: _hasTax && !_useIGST ? NumberText.parse(_cgstCtrl.text) : 0,
      igstRate: _hasTax && _useIGST ? NumberText.parse(_igstCtrl.text) : 0,
      taxAmount: _taxAmount,
      grandTotal: _grandTotal,
      status: _status,
      customFields: DocumentCustomField.forSave(_customFields),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currency: _currency,
      createdAt: widget.existingEstimate?.createdAt ?? now,
      updatedAt: now,
      lineItems: _items,
      convertedInvoiceId: widget.existingEstimate?.convertedInvoiceId,
    );
  }

  /// Saves the estimate. Returns the saved estimate, or null if it could not
  /// be saved (the reason has been shown).
  Future<EstimateModel?> _saveEstimate({bool popAfter = true}) async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseEnterOrSelectAClientName)),
      );
      return null;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addLineItemValidation)),
      );
      return null;
    }

    if (_estimateNumberCtrl.text.trim().isEmpty) {
      _estimateNumberCtrl.text = await DbProvider.getNextEstimateNumber();
    }

    setState(() => _isSaving = true);

    try {
      final estimate = _buildEstimateModel();
      await DbProvider.saveEstimate(estimate);
      await DocumentFieldPreferences.remember(estimate.customFields);

      // Template for this estimate, stored as the id the renderer reads.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('estimate_theme_${estimate.id}', _selectedTheme.id.value);
      if (_customDesign != null) {
        await prefs.setString('estimate_customization_${estimate.id}', _customDesign!.toJsonString());
      } else if (_selectedTheme.id != _initialThemeId) {
        // A newly picked template replaces an older custom design.
        await prefs.remove('estimate_customization_${estimate.id}');
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (popAfter) {
          Navigator.pop(context, true);
        }
      }
      return estimate;
    } on DuplicateNumberException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.estimateNumberIsAlreadyUsedPickAnotherNumber(e.number))),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Save estimate failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveTheEstimatePleaseTryAgain)),
        );
      }
      return null;
    }
  }

  /// Saves, then shows the preview in place of the editor, so a stale editor
  /// can never be saved over changes made from the preview.
  Future<void> _openPreview() async {
    final saved = await _saveEstimate(popAfter: false);
    if (saved == null || !mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EstimatePreviewScreen(estimate: saved),
      ),
    );
  }

  void _showItemDialog({LineItemModel? existingItem, int? index}) {
    final descCtrl = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: existingItem != null ? NumberText.trim(existingItem.quantity) : '1',
    );
    final priceCtrl = TextEditingController(
      text: existingItem != null ? NumberText.trim(existingItem.unitPrice) : '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.squircleGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppIcons.items,
                          color: AppColors.squircleGreenIcon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingItem == null ? context.l10n.addItemService : context.l10n.editItem,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.enterDescriptionQuantityRate,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: context.l10n.descriptionItemName,
                hint: context.l10n.eGWebsiteDesignConsultationParts,
                controller: descCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? context.l10n.required : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: context.l10n.requiredQuantity,
                      hint: '1',
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = NumberText.parse(v, fallback: -1);
                        if (parsed <= 0) return context.l10n.invalid;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: context.l10n.requiredUnitPrice,
                      hint: '0.00',
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText:
                          '${CurrencyFormatter.getCurrencySymbol(_currency)} ',
                      validator: (v) {
                        final parsed = NumberText.parse(v, fallback: -1);
                        if (parsed < 0) return context.l10n.invalid;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final qty = NumberText.parse(qtyCtrl.text, fallback: 1);
                      final price = NumberText.parse(priceCtrl.text);

                      setState(() {
                        if (existingItem != null && index != null) {
                          // Keeps the line's own discount, tax, HSN and unit.
                          _items[index] = LineItemModel.create(
                            id: existingItem.id,
                            invoiceId: existingItem.invoiceId,
                            description: descCtrl.text.trim(),
                            quantity: qty,
                            unitPrice: price,
                            discountRate: existingItem.discountRate,
                            taxRate: existingItem.taxRate,
                            hsnSac: existingItem.hsnSac,
                            unit: existingItem.unit,
                            sortOrder: index,
                          );
                        } else {
                          _items.add(
                            LineItemModel.create(
                              id: const Uuid().v4(),
                              invoiceId: _activeEstimateId ?? '',
                              description: descCtrl.text.trim(),
                              quantity: qty,
                              unitPrice: price,
                              sortOrder: _items.length,
                            ),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    existingItem == null ? context.l10n.addToEstimate : context.l10n.saveChanges,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickClient() async {
    final result = await Navigator.push<ClientModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientListScreen(selectionMode: true),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedClient = result;
        _clientNameCtrl.text = result.name;
        _clientEmailCtrl.text = result.email ?? '';
        _clientPhoneCtrl.text = result.phone ?? '';
        _clientAddressCtrl.text = result.address ?? '';
        _clientGstinCtrl.text = result.gstin ?? '';
      });
    }
  }

  Future<void> _pickTheme() async {
    final chosen = await PdfThemePickerSheet.show(
      context,
      currentTheme: _selectedTheme,
    );
    if (chosen == null || !mounted) return;
    // Re-applying the template a new estimate started with keeps the custom
    // default design (as an existing estimate keeps its own design), unless
    // the picker has just replaced that default with the plain template.
    InvoiceCustomizationConfig? inherited;
    if (widget.existingEstimate == null && chosen.customConfig == null && chosen.theme.id == _initialThemeId) {
      final def = await InvoiceRenderService.defaultCustomDesign();
      if (def?.themeId == chosen.theme.id) inherited = def;
      if (!mounted) return;
    }
    setState(() {
      _selectedTheme = chosen.theme;
      _customDesign = chosen.customConfig ?? inherited;
    });
  }

  /// What the user has entered, to tell whether leaving would lose work.
  String? _initialSignature;
  String get _editSignature => [
        _estimateNumberCtrl.text, _clientNameCtrl.text, _clientEmailCtrl.text,
        _clientPhoneCtrl.text, _clientAddressCtrl.text, _clientGstinCtrl.text,
        _estimateDate.toIso8601String(), _expiryDate?.toIso8601String(),
        for (final i in _items) '${i.description}|${i.quantity}|${i.unitPrice}|${i.discountRate}|${i.taxRate}',
        _hasDiscount, _discountType, _discountCtrl.text, _hasTax, _useIGST,
        _sgstCtrl.text, _cgstCtrl.text, _igstCtrl.text, _notesCtrl.text,
        DocumentCustomField.encode(_customFields),
        _currency, _selectedTheme.id,
      ].join('\u0001');

  Future<void> _confirmLeave(bool didPop) async {
    if (didPop) return;
    final dirty = _initialSignature != null && _editSignature != _initialSignature;
    if (dirty) {
      final discard = await AppDialog.showConfirmation(
        context: context,
        title: context.l10n.discardChanges,
        message: context.l10n.youHaveUnsavedChangesLeaveWithoutSavingThem,
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

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);
    final currencyProvider = context.watch<CurrencyProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _confirmLeave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              AppIcons.arrowBack,
              color: AppColors.textPrimary,
            ),
            // maybePop, so the unsaved-changes check runs.
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.existingEstimate != null ? context.l10n.editEstimate : context.l10n.createEstimate,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.pdfTemplates,
              icon: Icon(AppIcons.palette, color: AppColors.primary),
              onPressed: _pickTheme,
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            children: [
              // 1. Estimate Number & Validity Card
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: context.l10n.estimateNumber,
                            controller: _estimateNumberCtrl,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _estimateDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _estimateDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: context.l10n.estimateDate,
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy', context.localeName).format(_estimateDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Valid Until Date with quick pills
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _expiryDate ??
                                    DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _expiryDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: context.l10n.validUntilExpiry,
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _expiryDate != null
                                    ? DateFormat('dd/MM/yyyy', context.localeName).format(_expiryDate!)
                                    : context.l10n.noExpiry,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          context.l10n.quickValidity,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        _buildQuickDateChip(context.l10n.validForSevenDays, 7),
                        const SizedBox(width: 6),
                        _buildQuickDateChip(context.l10n.validForFourteenDays, 14),
                        const SizedBox(width: 6),
                        _buildQuickDateChip(context.l10n.validForThirtyDays, 30),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Template / PDF Theme Card
              _buildCardContainer(
                onTap: _pickTheme,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppIcons.palette,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.pdfTheme,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            context.l10n.catalogLabel(_selectedTheme.name),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      AppIcons.chevronRight,
                      color: AppColors.slate400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Bill From & Bill To
              _buildCardContainer(
                child: Column(
                  children: [
                    // Bill From
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.squircleBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppIcons.storefront,
                          color: AppColors.squircleBlueIcon,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        context.l10n.billFrom,
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      subtitle: Text(
                        _bizName ?? context.l10n.myBusinessPlaceholder,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    // Bill To
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.statusPartiallyPaidBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.person,
                            color: AppColors.statusPartiallyPaid,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.billToClient,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                              Text(
                                _clientNameCtrl.text.isEmpty
                                    ? context.l10n.selectAddClient
                                    : _clientNameCtrl.text,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: _clientNameCtrl.text.isEmpty
                                      ? AppColors.slate400
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.selectClient,
                          icon: Icon(
                            AppIcons.contacts,
                            color: AppColors.primary,
                          ),
                          onPressed: _pickClient,
                        ),
                      ],
                    ),
                    if (_selectedClient == null) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: context.l10n.clientName,
                        hint: context.l10n.johnDoeApexCorp,
                        controller: _clientNameCtrl,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Line Items Card
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.itemsServices,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(AppIcons.items, size: 16),
                              label: Text(context.l10n.catalog),
                              onPressed: () async {
                                final picked = await ItemPickerSheet.show(
                                  context,
                                  invoiceId: _activeEstimateId ?? '',
                                  currencyCode: _currency,
                                );
                                if (picked != null && picked.isNotEmpty) {
                                  setState(() => _items.addAll(picked));
                                }
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(AppIcons.add, size: 18),
                              label: Text(context.l10n.addItem),
                              onPressed: () => _showItemDialog(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              AppIcons.items,
                              size: 36,
                              color: AppColors.slate300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.noItemsAddedYet,
                              style: TextStyle(
                                color: AppColors.slate500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${NumberText.trim(item.quantity)} x ${CurrencyFormatter.format(item.unitPrice, currencyCode: _currency, currencySymbol: currencySymbol)}',
                                      style: TextStyle(
                                        color: AppColors.slate500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.total, currencyCode: _currency, currencySymbol: currencySymbol),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  AppIcons.edit,
                                  size: 18,
                                  color: AppColors.slate400,
                                ),
                                onPressed: () =>
                                    _showItemDialog(existingItem: item, index: i),
                              ),
                              IconButton(
                                icon: Icon(
                                  AppIcons.delete,
                                  size: 18,
                                  color: AppColors.accentRed,
                                ),
                                onPressed: () =>
                                    setState(() => _items.removeAt(i)),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. Discount, Taxes & Totals
              _buildCardContainer(
                child: Column(
                  children: [
                    // Subtotal
                    _buildSummaryRow(
                      context.l10n.subtotal,
                      CurrencyFormatter.format(_subtotal, currencyCode: _currency, currencySymbol: currencySymbol),
                    ),
                    const SizedBox(height: 8),

                    // Discount switch & inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.discount,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (v) => setState(() => _hasDiscount = v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasDiscount) ...[
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('%'),
                            selected: _discountType == DiscountType.percentage,
                            onSelected: (_) => setState(
                              () => _discountType = DiscountType.percentage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(currencySymbol),
                            selected: _discountType == DiscountType.flat,
                            onSelected: (_) =>
                                setState(() => _discountType = DiscountType.flat),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              hint: '0',
                              controller: _discountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context.l10n.discountAmount,
                        '-${CurrencyFormatter.format(_discountAmount, currencyCode: _currency, currencySymbol: currencySymbol)}',
                        isNegative: true,
                      ),
                    ],
                    const Divider(height: 20),

                    // Tax switch & inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currencyProvider.taxIdLabel.isNotEmpty
                              ? currencyProvider.taxIdLabel
                              : context.l10n.tax,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: _hasTax,
                          onChanged: (v) => setState(() => _hasTax = v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasTax) ...[
                      if (currencyProvider.isDualTax) ...[
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('CGST + SGST'),
                              selected: !_useIGST,
                              onSelected: (_) => setState(() => _useIGST = false),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('IGST'),
                              selected: _useIGST,
                              onSelected: (_) => setState(() => _useIGST = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!_useIGST)
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'SGST %',
                                  controller: _sgstCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'CGST %',
                                  controller: _cgstCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          )
                        else
                          CustomTextField(
                            label: 'IGST %',
                            controller: _igstCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                      ] else ...[
                        CustomTextField(
                          label:
                              '${context.l10n.catalogLabel(currencyProvider.selectedCurrency.defaultTax.shortName)} %',
                          controller: _igstCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context.l10n.taxAmount,
                        '+${CurrencyFormatter.format(_taxAmount, currencyCode: _currency, currencySymbol: currencySymbol)}',
                      ),
                    ],
                    const Divider(height: 24),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.totalEstimated,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_grandTotal, currencyCode: _currency, currencySymbol: currencySymbol),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 6. Currency & Settings Card
              _buildCardContainer(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      CurrencyPickerSheet.show(
                        context,
                        selectedCode: _currency,
                        onCurrencySelected: (curr) {
                          setState(() => _currency = curr.code);
                          Navigator.pop(context);
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.payments,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.currency,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$_currency $currencySymbol',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          AppIcons.chevronRight,
                          color: AppColors.slate400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_initialSignature != null) ...[
                CustomFieldsCard(
                  initialFields: _customFields,
                  recentLabels: _recentFieldLabels,
                  onChanged: (fields) => setState(() => _customFields = fields),
                ),
                const SizedBox(height: 12),
              ],

              // 7. Notes & Terms Card
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.notesTerms,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      hint: context.l10n.eGEstimateValidFor30DaysPayment,
                      controller: _notesCtrl,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _openPreview,
                    child: Text(
                      context.l10n.previewPdf,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => _saveEstimate(popAfter: true),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            context.l10n.saveEstimate,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expiryDate = _estimateDate.add(Duration(days: days));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isNegative = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.slate600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isNegative ? AppColors.statusOverdue : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
