import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/utils/image_store.dart';
import '../../../core/utils/document_totals.dart';
import '../../../core/utils/number_text.dart';
import '../../../core/utils/payment_terms.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/billing/free_limits.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../clients/models/client_model.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../models/invoice_customization_config.dart';
import '../models/document_custom_field.dart';
import '../widgets/custom_fields_card.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../widgets/pdf_theme_picker_sheet.dart';
import 'invoice_preview_screen.dart';
import '../services/invoice_actions.dart';
import '../services/invoice_render_service.dart';
import '../widgets/payments_sheet.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/app_popup_menu.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../items/screens/item_picker_sheet.dart';
import '../../../core/theme/app_icons.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? existingInvoice;
  final ClientModel? prefilledClient;

  const CreateInvoiceScreen({
    super.key,
    this.existingInvoice,
    this.prefilledClient,
  });

  /// Kept for existing callers; see [FreeLimits.canCreateInvoice].
  static Future<bool> canCreateNewInvoice(BuildContext context) => FreeLimits.canCreateInvoice(context);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _scrollController = ScrollController();

  // Invoice Number & Dates
  final _invoiceNumberCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  // Business (Bill From)
  String? _bizName;
  String? _bizAddress;
  String? _bizPhone;
  String? _bizEmail;
  String? _bizGstin;

  // Client (Bill To)
  ClientModel? _selectedClient;

  /// True once the user removes the invoice's original client, so the saved
  /// invoice no longer links to it.
  bool _clientDetached = false;
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientGstinCtrl = TextEditingController();

  // Line Items
  final List<LineItemModel> _items = [];

  // Financial calculations
  bool _hasDiscount = false;
  DiscountType _discountType = DiscountType.percentage;
  final _discountCtrl = TextEditingController(text: '0');

  bool _hasTax = false;
  bool _useIGST = false;
  final _sgstCtrl = TextEditingController(text: '9');
  final _cgstCtrl = TextEditingController(text: '9');
  final _igstCtrl = TextEditingController(text: '18');

  double _shippingFee = 0.0;
  PdfThemeId? _initialThemeId;
  InvoiceCustomizationConfig? _customDesign;
  double _paidAmount = 0.0;

  // Settings & Details
  String _currency = 'INR';
  String _paymentMethod = '';
  String? _signaturePath;
  List<DocumentCustomField> _customFields = const [];
  List<String> _recentFieldLabels = const [];
  final _notesCtrl = TextEditingController(text: 'Thanks for your business.');
  static const _maxAttachments = 5;
  final List<String> _attachments = [];
  final Set<String> _newAttachments = {};
  bool _pickingAttachment = false;
  Future<void>? _attachmentSave;
  InvoiceStatus _status = InvoiceStatus.unpaid;
  PdfTheme _selectedTheme = PdfTheme.defaultTheme;

  String? _activeInvoiceId;
  bool _isSaving = false;

  // Coachmarks / Tips management
  final Set<String> _dismissedTips = {};

  @override
  void initState() {
    super.initState();
    _attachments.addAll(widget.existingInvoice?.attachments ?? const []);
    _loadInitialData();
  }

  @override
  void dispose() {
    unawaited(_discardUnsavedAttachments());
    _invoiceNumberCtrl.dispose();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;
    final defaultTax = currencyProvider.defaultTax.rate;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _recentFieldLabels = DocumentFieldPreferences.recent(prefs);
    _customFields = widget.existingInvoice?.customFields ?? DocumentFieldPreferences.defaults(prefs);

    _bizName = prefs.getString('biz_name');
    _bizAddress = prefs.getString('biz_address');
    _bizPhone = prefs.getString('biz_phone');
    _bizEmail = prefs.getString('biz_email');
    _bizGstin = prefs.getString('biz_gstin');
    _signaturePath = prefs.getString('biz_signature_path');

    final savedDismissed = prefs.getStringList('dismissed_invoice_tips') ?? [];
    _dismissedTips.addAll(savedDismissed);

    final design = await InvoiceRenderService.designForInvoice(widget.existingInvoice?.id);
    _selectedTheme = PdfTheme.fromId(design.themeId.value);
    _initialThemeId = _selectedTheme.id;
    if (widget.existingInvoice == null) {
      // A new invoice inherits the custom default design in full, not just
      // its template, until a template is picked in this editor.
      _customDesign = await InvoiceRenderService.defaultCustomDesign();
    }

    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _activeInvoiceId = inv.id;
      _invoiceNumberCtrl.text = inv.invoiceNumber;
      _invoiceDate = inv.invoiceDate;
      _dueDate = inv.dueDate;
      _clientNameCtrl.text = inv.clientName;
      _clientEmailCtrl.text = inv.clientEmail ?? '';
      _clientPhoneCtrl.text = inv.clientPhone ?? '';
      _clientAddressCtrl.text = inv.clientAddress ?? '';
      _clientGstinCtrl.text = inv.clientGstin ?? '';
      _currency = inv.currency;
      _notesCtrl.text = inv.notes ?? ''; // a cleared note stays cleared
      _status = inv.status == InvoiceStatus.overdue
          ? InvoiceModel.paymentStatusFor(inv.paidAmount, inv.grandTotal)
          : inv.status;
      _paidAmount = inv.paidAmount;
      _shippingFee = inv.shipping;
      if (inv.issuerSnapshot != null) {
        final issuer = InvoiceRenderService.profileFromSnapshot(inv.issuerSnapshot, inv.currency);
        _signaturePath = issuer?.signaturePath ?? _signaturePath;
      }

      _items.addAll(inv.lineItems);

      if (inv.discountType != DiscountType.none && inv.discountValue > 0) {
        _hasDiscount = true;
        _discountType = inv.discountType;
        _discountCtrl.text = NumberText.trim(inv.discountValue);
      }

      if (inv.sgstRate > 0 || inv.cgstRate > 0 || inv.igstRate > 0) {
        _hasTax = true;
        if (inv.igstRate > 0) {
          _useIGST = true;
          _igstCtrl.text = NumberText.trim(inv.igstRate);
        } else {
          _sgstCtrl.text = NumberText.trim(inv.sgstRate);
          _cgstCtrl.text = NumberText.trim(inv.cgstRate);
        }
      }
    } else {
      // New Invoice
      _invoiceNumberCtrl.text = await DbProvider.getNextInvoiceNumber();
      final termsDays = paymentTermsDays(prefs.getString('default_payment_terms'));
      _dueDate = _invoiceDate.add(Duration(days: termsDays));
      final defaultNotes = prefs.getString('biz_notes');
      if (defaultNotes != null && defaultNotes.trim().isNotEmpty) {
        _notesCtrl.text = defaultNotes.trim();
      }

      if (defaultTax > 0) {
        _hasTax = true;
        if (currencyProvider.isDualTax) {
          final half = defaultTax / 2;
          _sgstCtrl.text = NumberText.trim(half);
          _cgstCtrl.text = NumberText.trim(half);
        } else {
          _useIGST = true;
          _igstCtrl.text = NumberText.trim(defaultTax);
        }
      }

      if (widget.prefilledClient != null) {
        final c = widget.prefilledClient!;
        _selectedClient = c;
        _clientNameCtrl.text = c.name;
        _clientEmailCtrl.text = c.email ?? '';
        _clientPhoneCtrl.text = c.phone ?? '';
        _clientAddressCtrl.text = c.address ?? '';
        _clientGstinCtrl.text = c.gstin ?? '';
      }
    }

    _initialSignature = _editSignature;
    if (mounted) setState(() {});
  }

  Future<void> _dismissTip(String tipKey) async {
    setState(() => _dismissedTips.add(tipKey));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_invoice_tips', _dismissedTips.toList());
  }

  // Calculations: one shared function, so the editor, the saved row and the
  // PDF always agree.
  DocumentTotals get _totals => DocumentTotals.forCurrency(
        currencyCode: _currency,
        lines: _items,
        discountType: _hasDiscount ? _discountType : DiscountType.none,
        discountValue: _hasDiscount ? NumberText.parse(_discountCtrl.text) : 0,
        sgstRate: (!_hasTax || _useIGST) ? 0 : NumberText.parse(_sgstCtrl.text),
        cgstRate: (!_hasTax || _useIGST) ? 0 : NumberText.parse(_cgstCtrl.text),
        igstRate: (_hasTax && _useIGST) ? NumberText.parse(_igstCtrl.text) : 0,
        shipping: _shippingFee,
      );

  double get _discountAmount => _totals.discountAmount;
  double get _taxAmount => _totals.taxAmount;
  double get _grandTotal => _totals.grandTotal;
  double get _balanceDue => (_grandTotal - _paidAmount).clamp(0, double.infinity);

  String get _currencySymbol => CurrencyFormatter.getCurrencySymbol(_currency);

  /// Removes the client and every contact detail copied from it.
  void _clearClient() {
    _selectedClient = null;
    _clientDetached = true;
    for (final c in [_clientNameCtrl, _clientEmailCtrl, _clientPhoneCtrl, _clientAddressCtrl, _clientGstinCtrl]) {
      c.clear();
    }
  }

  InvoiceModel _buildInvoiceModel({String? issuerSnapshot}) {
    final now = DateTime.now();
    final invoiceId = _activeInvoiceId ?? const Uuid().v4();
    _activeInvoiceId = invoiceId;

    final lineItems = _items.asMap().entries.map((e) {
      return e.value.copyWith(
        id: e.value.id.isEmpty ? const Uuid().v4() : e.value.id,
        invoiceId: invoiceId,
        sortOrder: e.key,
      );
    }).toList();

    final totals = _totals;
    return InvoiceModel(
      id: invoiceId,
      invoiceNumber: _invoiceNumberCtrl.text.trim(),
      clientId: _selectedClient?.id ?? (_clientDetached ? null : widget.existingInvoice?.clientId),
      clientName: _clientNameCtrl.text.trim(),
      clientEmail: _clientEmailCtrl.text.trim().isEmpty ? null : _clientEmailCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim().isEmpty ? null : _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim().isEmpty ? null : _clientAddressCtrl.text.trim(),
      clientGstin: _clientGstinCtrl.text.trim().isEmpty ? null : _clientGstinCtrl.text.trim(),
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      subtotal: totals.subtotal,
      discountType: _hasDiscount ? _discountType : DiscountType.none,
      discountValue: _hasDiscount ? NumberText.parse(_discountCtrl.text) : 0,
      discountAmount: totals.discountAmount,
      sgstRate: (!_hasTax || _useIGST) ? 0 : NumberText.parse(_sgstCtrl.text),
      cgstRate: (!_hasTax || _useIGST) ? 0 : NumberText.parse(_cgstCtrl.text),
      igstRate: (_hasTax && _useIGST) ? NumberText.parse(_igstCtrl.text) : 0,
      taxAmount: totals.taxAmount,
      shipping: totals.shipping,
      grandTotal: totals.grandTotal,
      // Keep the status consistent with the payments and the (possibly
      // changed) total, e.g. a "Paid" invoice whose total went up.
      paidAmount: _paidAmount.clamp(0, totals.grandTotal).toDouble(),
      status: InvoiceModel.paymentStatusFor(_paidAmount, totals.grandTotal),
      customFields: DocumentCustomField.forSave(_customFields),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currency: _currency,
      createdAt: widget.existingInvoice?.createdAt ?? now,
      updatedAt: now,
      lineItems: lineItems,
      attachments: List.unmodifiable(_attachments),
      issuerSnapshot: issuerSnapshot ?? widget.existingInvoice?.issuerSnapshot,
      sentAt: widget.existingInvoice?.sentAt,
    );
  }

  Future<void> _discardUnsavedAttachments() async {
    try {
      await _attachmentSave;
    } catch (_) {
      // A failed save leaves the newly picked files owned by this editor.
    }
    await Future.wait(_newAttachments.map(ImageStore.deleteAttachment));
  }

  Future<void> _pickAttachment() async {
    if (_pickingAttachment || _isSaving || _attachments.length >= _maxAttachments) return;
    setState(() => _pickingAttachment = true);
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(AppIcons.camera),
                title: Text(context.l10n.camera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(AppIcons.image),
                title: Text(context.l10n.gallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null || !mounted) return;
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;
      final path = await ImageStore.keep(picked.path, 'attachment');
      if (path == picked.path) throw StateError('Could not store the selected photo');
      if (!mounted) {
        await ImageStore.deleteAttachment(path);
        return;
      }
      setState(() {
        _newAttachments.add(path);
        _attachments.add(path);
      });
    } catch (e) {
      debugPrint('Attachment could not be added: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotAddThePhotoPleaseTryAgain)),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  void _viewAttachment(String path, int number) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(title: Text(context.l10n.numberedAttachment(number))),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(context.l10n.photoUnavailable),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.attach, color: AppColors.body, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.attachments, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      context.l10n.photoCount(_attachments.length, _maxAttachments),
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: context.l10n.addAttachment,
                onPressed: _isSaving || _pickingAttachment || _attachments.length >= _maxAttachments
                    ? null
                    : _pickAttachment,
                icon: const Icon(AppIcons.add),
              ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, path) in _attachments.indexed)
                  SizedBox.square(
                    dimension: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Semantics(
                            button: true,
                            label: context.l10n.viewNumberedAttachment(index + 1),
                            child: InkWell(
                              onTap: () => _viewAttachment(path, index + 1),
                              child: Image.file(
                                File(path),
                                cacheWidth: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: AppColors.surfaceStrong,
                                  child: Icon(AppIcons.image, color: AppColors.muted),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            tooltip: context.l10n.removeNumberedAttachment(index + 1),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.canvas,
                              foregroundColor: AppColors.ink,
                              minimumSize: const Size.square(32),
                              padding: EdgeInsets.zero,
                            ),
                            iconSize: 16,
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() => _attachments.removeAt(index));
                                    if (_newAttachments.remove(path)) {
                                      unawaited(ImageStore.deleteAttachment(path));
                                    }
                                  },
                            icon: const Icon(AppIcons.close),
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
    );
  }

  Future<InvoiceModel?> _saveInvoiceToDb() async {
    if (_isSaving || _pickingAttachment) return null;
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseAddAClientNameBillTo)),
      );
      _showClientSheet();
      return null;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseAddAtLeastOneLineItem)),
      );
      _showAddItemSheet();
      return null;
    }

    setState(() => _isSaving = true);
    try {
      if (_invoiceNumberCtrl.text.trim().isEmpty) {
        final number = await DbProvider.getNextInvoiceNumber();
        if (!mounted) return null;
        _invoiceNumberCtrl.text = number;
      }

      // The issuer details are frozen onto the invoice each time it is saved
      // from the editor, so later profile edits don't rewrite sent invoices.
      final snapshot = await InvoiceRenderService.captureIssuerSnapshot(
        signaturePath: _signaturePath,
      );
      if (!mounted) return null;
      final invoice = _buildInvoiceModel(issuerSnapshot: snapshot);
      _attachmentSave = DbProvider.saveInvoice(invoice).then((_) {
        _newAttachments.removeAll(invoice.attachments);
      });
      await _attachmentSave;
      await DocumentFieldPreferences.remember(invoice.customFields);
      await _persistThemeChoice(invoice.id);

      if (mounted) setState(() => _isSaving = false);
      return invoice;
    } on DuplicateNumberException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invoiceNumberIsAlreadyUsedPickAnotherNumber(e.number))),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Save invoice failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveTheInvoicePleaseTryAgain)),
        );
      }
      return null;
    }
  }

  /// Re-applying the template a new invoice started with keeps the custom
  /// default design (as an existing invoice keeps its own design), unless
  /// the picker has just replaced that default with the plain template.
  Future<InvoiceCustomizationConfig?> _inheritedDesignFor(PdfThemeChoice choice) async {
    if (widget.existingInvoice != null || choice.customConfig != null) return null;
    if (choice.theme.id != _initialThemeId) return null;
    final inherited = await InvoiceRenderService.defaultCustomDesign();
    return inherited?.themeId == choice.theme.id ? inherited : null;
  }

  /// Stores the template picked in the editor. A new invoice with no pick
  /// stores the custom default design it started from. An invoice whose
  /// design was customised in the preview keeps that design unless a
  /// different template was picked here.
  Future<void> _persistThemeChoice(String invoiceId) async {
    if (_customDesign != null) {
      await InvoiceRenderService.saveDesignForInvoice(invoiceId, _customDesign!);
    } else if (widget.existingInvoice == null || _selectedTheme.id != _initialThemeId) {
      await InvoiceRenderService.saveThemeForInvoice(invoiceId, _selectedTheme);
    }
  }

  Future<void> _handlePreview() async {
    final invoice = await _saveInvoiceToDb();
    if (invoice == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(invoice: invoice),
      ),
    );
  }

  Future<void> _handleSaveAndOpenPreview() async {
    final invoice = await _saveInvoiceToDb();
    if (invoice != null && mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePreviewScreen(invoice: invoice),
        ),
      );
    }
  }

  // --- Modular Bottom Sheets & Pickers ---

  void _showInvoiceHeaderSheet() {
    final numCtrl = TextEditingController(text: _invoiceNumberCtrl.text);
    DateTime tempDate = _invoiceDate;
    DateTime? tempDueDate = _dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isNoDueDate = tempDueDate == null;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.invoiceDetailsDates,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(AppIcons.close, color: AppColors.slate400),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Invoice Number Input
                  CustomTextField(
                    label: context.l10n.invoiceNumber,
                    hint: context.l10n.eGInv00001,
                    controller: numCtrl,
                  ),
                  const SizedBox(height: 16),

                  // 2. Invoice Issue Date
                  Text(
                    context.l10n.invoiceIssueDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: tempDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setSheetState(() {
                          final diff = tempDueDate?.difference(tempDate);
                          tempDate = picked;
                          if (diff != null) {
                            tempDueDate = tempDate.add(diff);
                          }
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.calendar, size: 16, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd MMMM yyyy', context.localeName).format(tempDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Icon(AppIcons.editCalendar, size: 18, color: AppColors.slate400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Payment Terms / Due Date (Optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.paymentTermsDueDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          Text(
                            context.l10n.optionalCreditPeriodForPayment,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                      if (!isNoDueDate)
                        Text(
                          DateFormat('dd MMM yyyy', context.localeName).format(tempDueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusPartiallyPaid,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Due Date Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDueDatePresetChip(
                        label: context.l10n.noDueDate,
                        isSelected: isNoDueDate,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = null;
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: context.l10n.dueOnReceipt,
                        isSelected: tempDueDate != null &&
                            tempDueDate!.year == tempDate.year &&
                            tempDueDate!.month == tempDate.month &&
                            tempDueDate!.day == tempDate.day,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate;
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: context.l10n.label7Days,
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 7,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 7));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: context.l10n.label15Days,
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 15,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 15));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: context.l10n.label30Days,
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 30,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 30));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: context.l10n.customDate,
                        isSelected: tempDueDate != null &&
                            ![0, 7, 15, 30].contains(
                              tempDueDate!.difference(tempDate).inDays,
                            ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tempDueDate ??
                                tempDate.add(const Duration(days: 14)),
                            firstDate: tempDate,
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              tempDueDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _invoiceNumberCtrl.text = numCtrl.text.trim().isNotEmpty
                              ? numCtrl.text.trim()
                              : 'INV00001';
                          _invoiceDate = tempDate;
                          _dueDate = tempDueDate;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        context.l10n.applyChanges,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDueDatePresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.slate100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (_) => onTap(),
    );
  }

  void _showBusinessSheet() {
    final nameCtrl = TextEditingController(text: _bizName ?? context.l10n.myBusinessPlaceholder);
    final addressCtrl = TextEditingController(text: _bizAddress ?? '');
    final phoneCtrl = TextEditingController(text: _bizPhone ?? '');
    final emailCtrl = TextEditingController(text: _bizEmail ?? '');
    final gstinCtrl = TextEditingController(text: _bizGstin ?? '');

    final currencyProvider = context.read<CurrencyProvider>();
    final taxIdLabel = currencyProvider.taxIdLabel;
    final taxIdHint = currencyProvider.taxIdHint;

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
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.billFromYourBusiness,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CustomTextField(label: context.l10n.businessName, controller: nameCtrl),
              const SizedBox(height: 12),
              CustomTextField(label: context.l10n.address, controller: addressCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: context.l10n.phone, controller: phoneCtrl, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: context.l10n.email, controller: emailCtrl, keyboardType: TextInputType.emailAddress)),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(label: taxIdLabel, hint: taxIdHint, controller: gstinCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('biz_name', nameCtrl.text.trim());
                    await prefs.setString('biz_address', addressCtrl.text.trim());
                    await prefs.setString('biz_phone', phoneCtrl.text.trim());
                    await prefs.setString('biz_email', emailCtrl.text.trim());
                    await prefs.setString('biz_gstin', gstinCtrl.text.trim());

                    if (mounted) {
                      setState(() {
                        _bizName = nameCtrl.text.trim();
                        _bizAddress = addressCtrl.text.trim();
                        _bizPhone = phoneCtrl.text.trim();
                        _bizEmail = emailCtrl.text.trim();
                        _bizGstin = gstinCtrl.text.trim();
                      });
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(context.l10n.saveBusinessInfo, style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClientSheet() async {
    final client = await Navigator.push<ClientModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientListScreen(selectionMode: true),
      ),
    );
    if (client != null && mounted) {
      setState(() {
        _selectedClient = client;
        _clientNameCtrl.text = client.name;
        _clientEmailCtrl.text = client.email ?? '';
        _clientPhoneCtrl.text = client.phone ?? '';
        _clientAddressCtrl.text = client.address ?? '';
        _clientGstinCtrl.text = client.gstin ?? '';
      });
    }
  }

  void _showAddItemSheet({int? editIndex}) {
    final item = editIndex != null ? _items[editIndex] : null;
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final qtyCtrl = TextEditingController(text: item != null ? NumberText.trim(item.quantity) : '1');
    final priceCtrl = TextEditingController(text: item != null ? NumberText.trim(item.unitPrice) : '');
    final discountCtrl = TextEditingController(
      text: item != null && item.discountRate > 0 ? NumberText.trim(item.discountRate) : '',
    );
    final taxCtrl = TextEditingController(
      text: item?.taxRate != null ? NumberText.trim(item!.taxRate!) : '',
    );
    bool showDiscountsAndTax = item != null && (item.discountRate > 0 || item.taxRate != null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final qty = NumberText.parse(qtyCtrl.text, fallback: 1);
          final price = NumberText.parse(priceCtrl.text);
          final discountPercent = NumberText.parse(discountCtrl.text).clamp(0.0, 100.0).toDouble();
          // Empty means "use the invoice's tax rate"; 0 means exempt.
          final double? ownTaxRate = taxCtrl.text.trim().isEmpty ? null : NumberText.parse(taxCtrl.text);
          final taxPercent = ownTaxRate ?? 0;

          final baseTotal = qty * price;
          final netTotal = LineItemModel.netAmountFor(qty, price, discountPercent);
          final discountAmount = baseTotal - netTotal;
          final taxAmount = netTotal * taxPercent / 100;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    editIndex != null ? context.l10n.editItem : context.l10n.addItem,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: context.l10n.description,
                    hint: context.l10n.eGConsultingDesignProduct,
                    controller: descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: context.l10n.quantity,
                          hint: '1',
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                icon: Icon(AppIcons.removeCircle, size: 18, color: AppColors.slate400),
                                onPressed: () {
                                  final current = NumberText.parse(qtyCtrl.text, fallback: 1);
                                  if (current > 1) {
                                    final next = current - 1;
                                    qtyCtrl.text = NumberText.trim(next);
                                    setSheetState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                icon: Icon(AppIcons.addCircle, size: 18, color: AppColors.primary),
                                onPressed: () {
                                  final current = NumberText.parse(qtyCtrl.text, fallback: 1);
                                  final next = current + 1;
                                  qtyCtrl.text = NumberText.trim(next);
                                  setSheetState(() {});
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: context.l10n.unitPrice,
                          hint: '0.00',
                          controller: priceCtrl,
                          prefixText: '$_currencySymbol ',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setSheetState(() => showDiscountsAndTax = !showDiscountsAndTax),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            showDiscountsAndTax ? AppIcons.chevronUp : AppIcons.chevronDown,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            showDiscountsAndTax ? context.l10n.hideItemDiscountTax : context.l10n.addItemDiscountTax,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showDiscountsAndTax) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: context.l10n.discountRequiredAmountLabel,
                            hint: '0',
                            controller: discountCtrl,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: context.l10n.taxRate,
                            hint: context.l10n.invoiceRate,
                            controller: taxCtrl,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (discountAmount > 0 || taxAmount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.l10n.baseAmount, style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                              Text(CurrencyFormatter.format(baseTotal, currencySymbol: _currencySymbol), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (discountAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.l10n.discountPercentLabel(NumberText.trim(discountPercent)), style: TextStyle(fontSize: 12, color: AppColors.statusPartiallyPaid)),
                                Text('-${CurrencyFormatter.format(discountAmount, currencySymbol: _currencySymbol)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusPartiallyPaid)),
                              ],
                            ),
                          if (taxAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.l10n.taxAtAddedInTotals(NumberText.trim(taxPercent)), style: TextStyle(fontSize: 12, color: AppColors.squircleGreenIcon)),
                                Text('+${CurrencyFormatter.format(taxAmount, currencySymbol: _currencySymbol)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.squircleGreenIcon)),
                              ],
                            ),
                          const Divider(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.l10n.lineAmountBeforeTax, style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              CurrencyFormatter.format(netTotal, currencySymbol: _currencySymbol),
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.pleaseEnterAnItemDescription)),
                          );
                          return;
                        }
                        if (qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.quantityMustBeMoreThan0)),
                          );
                          return;
                        }
                        final newItem = LineItemModel.create(
                          id: item?.id ?? const Uuid().v4(),
                          invoiceId: _activeInvoiceId ?? '',
                          description: descCtrl.text.trim(),
                          quantity: qty,
                          unitPrice: price,
                          discountRate: discountPercent,
                          taxRate: ownTaxRate,
                          hsnSac: item?.hsnSac,
                          unit: item?.unit,
                          sortOrder: editIndex ?? _items.length,
                        );

                        setState(() {
                          if (editIndex != null) {
                            _items[editIndex] = newItem;
                          } else {
                            _items.add(newItem);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(editIndex != null ? context.l10n.updateItem : context.l10n.addToInvoice, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDiscountSheet() {
    final valCtrl = TextEditingController(text: _discountCtrl.text);
    DiscountType tempType = _discountType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Text(context.l10n.addDiscount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(context.l10n.percentage)),
                      selected: tempType == DiscountType.percentage,
                      onSelected: (_) => setSheetState(() => tempType = DiscountType.percentage),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(context.l10n.flatAmount(_currencySymbol))),
                      selected: tempType == DiscountType.flat,
                      onSelected: (_) => setSheetState(() => tempType = DiscountType.flat),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: tempType == DiscountType.percentage ? context.l10n.discountPercentage : context.l10n.discountAmount,
                controller: valCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final val = NumberText.parse(valCtrl.text);
                    setState(() {
                      _hasDiscount = val > 0;
                      _discountType = tempType;
                      _discountCtrl.text = valCtrl.text;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(context.l10n.applyDiscount, style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaxSheet() {
    final currencyProvider = context.read<CurrencyProvider>();
    final isDual = currencyProvider.isDualTax;
    final defaultTax = currencyProvider.defaultTax;
    final taxName = context.l10n.catalogLabel(defaultTax.shortName);

    final igstCtrl = TextEditingController(text: _igstCtrl.text);
    final sgstCtrl = TextEditingController(text: _sgstCtrl.text);
    final cgstCtrl = TextEditingController(text: _cgstCtrl.text);
    bool useIGST = isDual ? _useIGST : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.configureNamedTax(taxName),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                isDual
                    ? context.l10n.chooseCgstSgstIntraStateOrIgstInter
                    : context.l10n.setPercentageToApplyToThisInvoice(taxName),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Quick preset chips for this country
              if (defaultTax.presetRates.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: defaultTax.presetRates.map((rate) {
                    final isPresetSelected = isDual
                        ? (useIGST
                            ? (double.tryParse(igstCtrl.text) ?? -1) == rate
                            : ((double.tryParse(sgstCtrl.text) ?? -1) + (double.tryParse(cgstCtrl.text) ?? -1)) == rate)
                        : (double.tryParse(igstCtrl.text) ?? -1) == rate;

                    return ActionChip(
                      label: Text(
                        rate == 0
                            ? context.l10n.noTax0
                            : '$taxName ${NumberText.trim(rate)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPresetSelected ? AppColors.onPrimary : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isPresetSelected ? AppColors.primary : AppColors.slate100,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setSheetState(() {
                          if (isDual && !useIGST) {
                            final half = rate / 2;
                            sgstCtrl.text = NumberText.trim(half);
                            cgstCtrl.text = NumberText.trim(half);
                          } else {
                            igstCtrl.text = NumberText.trim(rate);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (isDual) ...[
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('CGST + SGST')),
                        selected: !useIGST,
                        onSelected: (_) {
                          setSheetState(() {
                            useIGST = false;
                            final current = double.tryParse(igstCtrl.text) ?? defaultTax.rate;
                            final half = current / 2;
                            sgstCtrl.text = NumberText.trim(half);
                            cgstCtrl.text = NumberText.trim(half);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(context.l10n.igstSingle)),
                        selected: useIGST,
                        onSelected: (_) {
                          setSheetState(() {
                            useIGST = true;
                            final total = (NumberText.parse(sgstCtrl.text)) + (NumberText.parse(cgstCtrl.text));
                            igstCtrl.text = NumberText.trim(total > 0 ? total : defaultTax.rate);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (useIGST)
                  CustomTextField(
                    label: context.l10n.igstRate,
                    controller: igstCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'CGST (%)',
                          controller: cgstCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'SGST (%)',
                          controller: sgstCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                // Clean Single Tax Field
                CustomTextField(
                  label: context.l10n.namedTaxRatePercent(taxName),
                  hint: context.l10n.exampleValue(defaultTax.rate.toString()),
                  controller: igstCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _hasTax = false;
                          _igstCtrl.text = '0';
                          _sgstCtrl.text = '0';
                          _cgstCtrl.text = '0';
                        });
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(context.l10n.removeTax),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _useIGST = isDual ? useIGST : true;
                          _igstCtrl.text = igstCtrl.text.trim();
                          _sgstCtrl.text = sgstCtrl.text.trim();
                          _cgstCtrl.text = cgstCtrl.text.trim();
                          final totalTax = (isDual && !useIGST)
                              ? (NumberText.parse(sgstCtrl.text)) + (NumberText.parse(cgstCtrl.text))
                              : (NumberText.parse(igstCtrl.text));
                          _hasTax = totalTax > 0;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(context.l10n.applyTax, style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShippingSheet() {
    final ctrl = TextEditingController(text: _shippingFee > 0 ? NumberText.trim(_shippingFee) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(context.l10n.shippingCharges, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: context.l10n.shippingFee(_currencySymbol),
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _shippingFee = NumberText.parse(ctrl.text));
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                child: Text(context.l10n.saveShippingFee, style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The invoice as saved, or null if it has not been saved yet. Payments
  /// belong to the saved invoice, so they are managed against this.
  Future<InvoiceModel?> _storedInvoice() async {
    final id = _activeInvoiceId;
    if (id == null) return null;
    final rows = await DbProvider.query(DbProvider.tableInvoices, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : InvoiceModel.fromMap(rows.first);
  }

  /// Takes the paid amount and status from the saved invoice's payments.
  void _applyStoredPayment(InvoiceModel stored) {
    setState(() {
      _paidAmount = stored.paidAmount;
      _status = InvoiceModel.paymentStatusFor(stored.paidAmount, stored.grandTotal);
    });
  }

  /// Saved invoice: the payments list (record or delete payments).
  /// New invoice: the amount already received, saved as its first payment.
  Future<void> _openPayments() async {
    final stored = await _storedInvoice();
    if (!mounted) return;
    if (stored == null) {
      _showPaymentsSheet();
      return;
    }
    if (await PaymentsSheet.show(context, stored)) {
      final fresh = await _storedInvoice();
      if (fresh != null && mounted) _applyStoredPayment(fresh);
    }
  }

  /// Saved invoice: changes the status through its payments right away.
  Future<void> _setStatus(InvoiceStatus s) async {
    final stored = await _storedInvoice();
    if (!mounted) return;
    if (stored == null) {
      setState(() {
        _status = s;
        if (s == InvoiceStatus.paid && _paidAmount < _grandTotal) {
          _paidAmount = _grandTotal;
        } else if (s == InvoiceStatus.unpaid) {
          _paidAmount = 0;
        }
      });
      if (s == InvoiceStatus.partiallyPaid && (_paidAmount <= 0 || _paidAmount >= _grandTotal)) {
        _showPaymentsSheet();
      }
      return;
    }
    if (await InvoiceActions.changePaymentStatus(context, stored, s)) {
      final fresh = await _storedInvoice();
      if (fresh != null && mounted) _applyStoredPayment(fresh);
    }
  }

  void _showPaymentsSheet() {
    final ctrl = TextEditingController(text: _paidAmount > 0 ? _paidAmount.toString() : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(context.l10n.amountAlreadyReceived, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: context.l10n.amountPaid(_currencySymbol),
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final p = NumberText.parse(ctrl.text);
                  setState(() {
                    _paidAmount = p;
                    if (_paidAmount >= _grandTotal && _grandTotal > 0) {
                      _status = InvoiceStatus.paid;
                    } else if (_paidAmount > 0) {
                      _status = InvoiceStatus.partiallyPaid;
                    } else {
                      _status = InvoiceStatus.unpaid;
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                child: Text(context.l10n.save, style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet() {
    CurrencyPickerSheet.show(
      context,
      selectedCode: _currency,
      onCurrencySelected: (curr) {
        setState(() => _currency = curr.code);
        Navigator.pop(context);
      },
    );
  }

  void _showPaymentMethodSheet() {
    final methods = ['Bank Transfer / NEFT', 'UPI / GPay / PhonePe', 'Cash', 'Credit / Debit Card', 'Cheque', 'PayPal'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(context.l10n.selectPaymentMethod, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...methods.map((m) {
              final isSel = _paymentMethod == m;
              return ListTile(
                title: Text(context.l10n.catalogLabel(m), style: TextStyle(fontWeight: isSel ? FontWeight.w600 : FontWeight.w500)),
                trailing: isSel ? Icon(AppIcons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _paymentMethod = m);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showNotesSheet() {
    final ctrl = TextEditingController(text: _notesCtrl.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(context.l10n.termsNotes, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: context.l10n.termsSlashNotes,
              hint: context.l10n.eGThanksForYourBusiness,
              controller: ctrl,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _notesCtrl.text = ctrl.text.trim());
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                child: Text(context.l10n.saveNotes, style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(context.l10n.markInvoiceAs, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // Overdue is not picked: it shows automatically once the due
              // date passes with a balance left.
              ...[InvoiceStatus.unpaid, InvoiceStatus.partiallyPaid, InvoiceStatus.paid].map((s) {
                final isSel = _status == s;
                return ListTile(
                  title: Text(context.l10n.catalogLabel(s.label), style: TextStyle(fontWeight: isSel ? FontWeight.w600 : FontWeight.w500)),
                  trailing: isSel ? Icon(AppIcons.check, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _setStatus(s);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteInvoice() async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: context.l10n.deleteInvoiceQuestion,
      message: context.l10n.areYouSureYouWantToDeleteThis,
    );

    if (confirm == true && _activeInvoiceId != null) {
      await DbProvider.deleteInvoice(_activeInvoiceId!);
      await InvoiceRenderService.forgetInvoice(_activeInvoiceId!);
      await PdfHelper.deletePdf(_invoiceNumberCtrl.text);
      if (mounted) Navigator.pop(context, true);
    }
  }

  /// What the user has entered, to tell whether leaving would lose work.
  String? _initialSignature;
  String get _editSignature => [
        _invoiceNumberCtrl.text, _clientNameCtrl.text, _clientEmailCtrl.text,
        _clientPhoneCtrl.text, _clientAddressCtrl.text, _clientGstinCtrl.text,
        _invoiceDate.toIso8601String(), _dueDate?.toIso8601String(),
        for (final i in _items) '${i.description}|${i.quantity}|${i.unitPrice}|${i.discountRate}|${i.taxRate}',
        _hasDiscount, _discountType, _discountCtrl.text, _hasTax, _useIGST,
        _sgstCtrl.text, _cgstCtrl.text, _igstCtrl.text, _notesCtrl.text,
        DocumentCustomField.encode(_customFields),
        _shippingFee, _status, _paidAmount, _currency, _signaturePath, _selectedTheme.id,
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
    final isPro = context.watch<BillingService>().isPro;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDual = currencyProvider.isDualTax;
    final taxShortName = context.l10n.catalogLabel(currencyProvider.defaultTax.shortName);
    final currencySymbol = _currencySymbol;

    // Sequential coachmarks state evaluation
    final bool hasClient = _clientNameCtrl.text.trim().isNotEmpty && _clientNameCtrl.text.trim() != context.l10n.addClients;
    final bool hasItems = _items.isNotEmpty;
    final bool hasFinancials = _hasTax || _hasDiscount || _shippingFee > 0;
    final bool hasSettings = _paymentMethod.isNotEmpty || _signaturePath != null;

    // Determine which step is currently active in the sequence
    final bool showClientTip = !hasClient && !_dismissedTips.contains('client');
    final bool showItemsTip = hasClient && !hasItems && !_dismissedTips.contains('items') ||
        (!hasClient && _dismissedTips.contains('client') && !hasItems && !_dismissedTips.contains('items'));
    final bool showFinancialsTip = hasItems && !hasFinancials && !_dismissedTips.contains('financials') ||
        (!hasItems && _dismissedTips.contains('items') && !hasFinancials && !_dismissedTips.contains('financials'));
    final bool showSettingsTip = hasFinancials && !hasSettings && !_dismissedTips.contains('settings') ||
        (!hasFinancials && _dismissedTips.contains('financials') && !hasSettings && !_dismissedTips.contains('settings'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _confirmLeave(didPop),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ),
          leading: IconButton(
            icon: Icon(AppIcons.chevronBack, size: 18, color: AppColors.ink),
            // maybePop, so the unsaved-changes check runs.
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.existingInvoice != null ? context.l10n.editInvoice : context.l10n.createInvoice,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3),
          ),
          centerTitle: true,
          actions: [
            if (!isPro)
              IconButton(
                icon: Icon(AppIcons.premium, color: AppColors.proGold),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(AppIcons.moreVert, color: AppColors.ink, size: 20),
              onSelected: (val) async {
                if (val == 'clear') {
                  setState(() {
                    _items.clear();
                    _clearClient();
                  });
                } else if (val == 'reset_tips') {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('dismissed_invoice_tips');
                  setState(() => _dismissedTips.clear());
                }
              },
              itemBuilder: (_) => [
                AppPopupMenuItem.item(
                  value: 'clear',
                  title: context.l10n.clearItems,
                  icon: AppIcons.clearAll,
                  iconColor: AppColors.muted,
                ),
                AppPopupMenuItem.item(
                  value: 'reset_tips',
                  title: context.l10n.resetHelpfulTips,
                  icon: AppIcons.lightbulb,
                  iconColor: AppColors.ink,
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  children: [
                    // Card 1: Invoice Number & Due Date
                    _buildCard(
                      onTap: _showInvoiceHeaderSheet,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(9999), // pill
                                      border: Border.all(color: AppColors.hairline),
                                    ),
                                    child: Text(
                                      context.l10n.invoiceHeading,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _invoiceNumberCtrl.text.isNotEmpty
                                        ? _invoiceNumberCtrl.text
                                        : 'INV00001',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(AppIcons.edit, size: 18, color: AppColors.muted),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Invoice Date Pill
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.hairline),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(AppIcons.calendar, size: 13, color: AppColors.muted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd MMM yyyy', context.localeName).format(_invoiceDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Due Date Pill
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _dueDate != null
                                        ? AppColors.statusPartiallyPaidBg
                                        : AppColors.slate100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        AppIcons.hourglass,
                                        size: 13,
                                        color: _dueDate != null
                                            ? AppColors.statusPartiallyPaid
                                            : AppColors.slate400,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _dueDate != null
                                              ? context.l10n.dueDateLabel(DateFormat('dd MMM', context.localeName).format(_dueDate!))
                                              : context.l10n.noDueDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _dueDate != null
                                                ? AppColors.statusPartiallyPaid
                                                : AppColors.slate500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 2: Templates
                    _buildCard(
                      child: InkWell(
                        onTap: () async {
                          final selected = await PdfThemePickerSheet.show(
                            context,
                            currentTheme: _selectedTheme,
                            showSetAsDefault: true,
                          );
                          if (selected == null || !mounted) return;
                          final inherited = await _inheritedDesignFor(selected);
                          if (!mounted) return;
                          setState(() {
                            _selectedTheme = selected.theme;
                            _customDesign = selected.customConfig ?? inherited;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selectedTheme.previewBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedTheme.previewPrimary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                AppIcons.viewQuilt,
                                color: _selectedTheme.previewPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.templates,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.l10n.chooseStylePaperDesign,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _selectedTheme.previewBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _selectedTheme.previewPrimary.withValues(alpha: 0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 3,
                                    color: _selectedTheme.previewPrimary,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 22,
                                    height: 2,
                                    color: _selectedTheme.previewSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 22,
                                    height: 2,
                                    color: _selectedTheme.previewAccent,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(AppIcons.chevronRight, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 3: Connected Bill From & Bill To
                    _buildCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        children: [
                          // Bill From
                          GestureDetector(
                            onTap: _showBusinessSheet,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.squircleCyan,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.storefront, color: AppColors.squircleCyanIcon, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(context.l10n.billFrom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(
                                        _bizName == null
                                            ? context.l10n.myBusinessPlaceholder
                                            : _bizName!.isNotEmpty
                                                ? _bizName!
                                                : context.l10n.addBusiness,
                                        style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(AppIcons.chevronRight, color: AppColors.slate400),
                              ],
                            ),
                          ),
                          // Dotted Connector
                          Padding(
                            padding: const EdgeInsets.only(left: 19),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 16,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    3,
                                    (index) => Container(width: 2, height: 2, color: AppColors.slate300),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bill To
                          GestureDetector(
                            onTap: _showClientSheet,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.statusPartiallyPaidBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.clients, color: AppColors.statusPartiallyPaid, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(context.l10n.billTo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(
                                        _clientNameCtrl.text.isNotEmpty ? _clientNameCtrl.text : context.l10n.addClients,
                                        style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(AppIcons.chevronRight, color: AppColors.slate400),
                              ],
                            ),
                          ),

                          // Sequential Coachmark 1: Add Client
                          if (showClientTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: context.l10n.stepOfTotal(1, 4),
                              title: context.l10n.addYourClientOrCustomer,
                              subtitle: context.l10n.selectAnExistingClientOrCreateANew,
                              onTap: _showClientSheet,
                              onDismiss: () => _dismissTip('client'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 4: Items Section
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.squircleGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(AppIcons.items, color: AppColors.squircleGreenIcon, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.l10n.items, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text(
                                      _items.isEmpty ? context.l10n.addItems : context.l10n.addedItemCount(_items.length),
                                      style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await ItemPickerSheet.show(
                                    context,
                                    invoiceId: _activeInvoiceId ?? '',
                                    currencyCode: _currency,
                                  );
                                  if (picked != null && picked.isNotEmpty) {
                                    setState(() => _items.addAll(picked));
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.squirclePurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.items, color: AppColors.squirclePurpleIcon, size: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showAddItemSheet(),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.add, color: AppColors.onPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),

                          // Sequential Coachmark 2: Add Items
                          if (showItemsTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: context.l10n.stepOfTotal(2, 4),
                              title: context.l10n.createYourItemOrService,
                              subtitle: context.l10n.addNamePriceQuantityAndDetails,
                              onTap: () => _showAddItemSheet(),
                              onDismiss: () => _dismissTip('items'),
                            ),
                          ] else if (_items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            ..._items.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return Dismissible(
                                key: ValueKey('line_item_${item.id}_$idx'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusOverdueBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(AppIcons.delete, color: AppColors.accentRed, size: 20),
                                ),
                                onDismissed: (_) {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _items.removeAt(idx));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            Text(
                                              '${NumberText.trim(item.quantity)} x ${CurrencyFormatter.format(item.unitPrice, currencySymbol: _currencySymbol)}',
                                              style: TextStyle(fontSize: 12, color: AppColors.slate500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(item.total, currencySymbol: _currencySymbol),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: Icon(AppIcons.edit, size: 18, color: AppColors.slate500),
                                        onPressed: () => _showAddItemSheet(editIndex: idx),
                                      ),
                                      IconButton(
                                        icon: Icon(AppIcons.close, size: 18, color: AppColors.accentRed),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          setState(() => _items.removeAt(idx));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 5: Calculation & Totals Card (Discount, Tax, Shipping, Total)
                    _buildCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildRowTile(
                            icon: AppIcons.percent,
                            title: context.l10n.discount,
                            subtitle: _hasDiscount ? '(${_discountCtrl.text}${_discountType == DiscountType.percentage ? "%" : ""})' : '(0%)',
                            value: _hasDiscount
                                ? '-${CurrencyFormatter.format(_discountAmount, currencyCode: _currency, currencySymbol: currencySymbol)}'
                                : '-$currencySymbol 0.00',
                            onTap: _showDiscountSheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: AppIcons.bank,
                            title: taxShortName,
                            subtitle: _hasTax
                                ? (isDual && !_useIGST
                                    ? '(CGST ${_cgstCtrl.text}% + SGST ${_sgstCtrl.text}%)'
                                    : '(${_useIGST ? _igstCtrl.text : NumberText.trim((NumberText.parse(_sgstCtrl.text)) + (NumberText.parse(_cgstCtrl.text)))}%)')
                                : '(0%)',
                            value: CurrencyFormatter.format(_taxAmount, currencyCode: _currency, currencySymbol: currencySymbol),
                            onTap: _showTaxSheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: AppIcons.shipping,
                            title: context.l10n.shipping,
                            subtitle: '',
                            value: CurrencyFormatter.format(_shippingFee, currencyCode: _currency, currencySymbol: currencySymbol),
                            onTap: _showShippingSheet,
                          ),
                          const SizedBox(height: 12),
                          // Total Row Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.squircleBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.l10n.total, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(
                                  CurrencyFormatter.format(_grandTotal, currencyCode: _currency, currencySymbol: currencySymbol),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),

                          // Sequential Coachmark 3: Configure Discounts & Taxes
                          if (showFinancialsTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: context.l10n.stepOfTotal(3, 4),
                              title: context.l10n.configureDiscountTaxOrShipping,
                              subtitle: context.l10n.applyRatesDiscountsOrShippingCharges(taxShortName),
                              onTap: _showTaxSheet,
                              onDismiss: () => _dismissTip('financials'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 6: Payments & Balance Card
                    _buildCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildRowTile(
                            icon: AppIcons.coins,
                            title: context.l10n.payments,
                            subtitle: '',
                            value: CurrencyFormatter.format(_paidAmount, currencyCode: _currency, currencySymbol: currencySymbol),
                            onTap: _openPayments,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.squircleBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.l10n.balanceDueHeading, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(
                                  CurrencyFormatter.format(_balanceDue, currencyCode: _currency, currencySymbol: currencySymbol),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 7: Settings / Details
                    _buildCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildRowTile(
                            icon: AppIcons.payments,
                            title: context.l10n.currency,
                            subtitle: '',
                            value: '$_currency $_currencySymbol',
                            onTap: _showCurrencySheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: AppIcons.creditCard,
                            title: context.l10n.paymentMethod,
                            subtitle: '',
                            value: context.l10n.catalogLabel(_paymentMethod),
                            onTap: _showPaymentMethodSheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: AppIcons.draw,
                            title: context.l10n.signature,
                            subtitle: '',
                            value: _signaturePath != null ? context.l10n.signatureAttached : context.l10n.addSignature,
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                // For this invoice only; the profile signature
                                // stays as it is.
                                final kept = await ImageStore.keep(img.path, 'signature');
                                if (!mounted) return;
                                setState(() => _signaturePath = kept);
                              }
                            },
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: AppIcons.assignment,
                            title: context.l10n.termsOrNotes,
                            subtitle: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : context.l10n.thanksForYourBusiness,
                            value: '',
                            onTap: _showNotesSheet,
                          ),

                          // Sequential Coachmark 4: Payment Method & Signature
                          if (showSettingsTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: context.l10n.stepOfTotal(4, 4),
                              title: context.l10n.setPaymentMethodSignature,
                              subtitle: context.l10n.addUpiBankDetailsNotesOrYourSignature,
                              onTap: _showPaymentMethodSheet,
                              onDismiss: () => _dismissTip('settings'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildAttachmentsCard(),
                    const SizedBox(height: 12),

                    if (_initialSignature != null) ...[
                      CustomFieldsCard(
                        initialFields: _customFields,
                        recentLabels: _recentFieldLabels,
                        onChanged: (fields) => setState(() => _customFields = fields),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Card 9: Status
                    _buildCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildRowTile(
                            icon: AppIcons.factCheck,
                            title: context.l10n.markAs,
                            subtitle: '',
                            value: context.l10n.catalogLabel(_status.label),
                            onTap: _showStatusSheet,
                          ),
                        ],
                      ),
                    ),

                    // Card 10: Delete Invoice (if editing)
                    if (widget.existingInvoice != null) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        onTap: _handleDeleteInvoice,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.delete, color: AppColors.accentRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              context.l10n.deleteInvoice,
                              style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky Bottom Bar with [Preview] and [Save] in Cal.com style
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSaving || _pickingAttachment ? null : _handlePreview,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.hairline, width: 1.0),
                        shape: const StadiumBorder(),
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                      ),
                      child: Text(
                        context.l10n.preview,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving || _pickingAttachment ? null : _handleSaveAndOpenPreview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                            )
                          : Text(
                              context.l10n.save,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
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

  Widget _buildCoachmarkBalloon({
    required String stepLabel,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.proBadgeBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkElevated,
                    borderRadius: BorderRadius.circular(9999), // pill
                  ),
                  child: Text(
                    stepLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.onDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDismiss();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(AppIcons.close, color: AppColors.onDarkSoft, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(color: AppColors.onDark, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: AppColors.onDarkSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12), // rounded.lg
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: child,
      ),
    );
  }

  Widget _buildRowTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (value.isNotEmpty) ...[
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(width: 4),
          ],
          Icon(AppIcons.chevronRight, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}
