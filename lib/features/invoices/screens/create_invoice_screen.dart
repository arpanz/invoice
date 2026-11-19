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
  String _bizName = 'My Business';
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
  final _notesCtrl = TextEditingController(text: 'Thanks for your business.');
  final List<String> _attachments = [];
  InvoiceStatus _status = InvoiceStatus.unpaid;
  bool _showPaidStamp = true;
  PdfTheme _selectedTheme = PdfTheme.defaultTheme;

  String? _activeInvoiceId;
  bool _isSaving = false;

  // Coachmarks / Tips management
  final Set<String> _dismissedTips = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
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
    _bizName = prefs.getString('biz_name') ?? 'My Business';
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
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currency: _currency,
      createdAt: widget.existingInvoice?.createdAt ?? now,
      updatedAt: now,
      lineItems: lineItems,
      issuerSnapshot: issuerSnapshot ?? widget.existingInvoice?.issuerSnapshot,
      sentAt: widget.existingInvoice?.sentAt,
    );
  }

  Future<InvoiceModel?> _saveInvoiceToDb() async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a client name (Bill To).')),
      );
      _showClientSheet();
      return null;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item.')),
      );
      _showAddItemSheet();
      return null;
    }

    if (_invoiceNumberCtrl.text.trim().isEmpty) {
      _invoiceNumberCtrl.text = await DbProvider.getNextInvoiceNumber();
    }

    setState(() => _isSaving = true);
    try {
      // The issuer details are frozen onto the invoice each time it is saved
      // from the editor, so later profile edits don't rewrite sent invoices.
      final snapshot = await InvoiceRenderService.captureIssuerSnapshot(
        signaturePath: _signaturePath,
      );
      final invoice = _buildInvoiceModel(issuerSnapshot: snapshot);
      await DbProvider.saveInvoice(invoice);
      await _persistThemeChoice(invoice.id);

      if (mounted) setState(() => _isSaving = false);
      return invoice;
    } on DuplicateNumberException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice number ${e.number} is already used. Pick another number.')),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Save invoice failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the invoice. Please try again.')),
        );
      }
      return null;
    }
  }

  /// Stores the template picked in the editor. An invoice whose design was
  /// customised in the preview keeps that design unless a different template
  /// was picked here.
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
                        'Invoice Details & Dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.slate400),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Invoice Number Input
                  CustomTextField(
                    label: 'Invoice Number',
                    hint: 'e.g. INV00001',
                    controller: numCtrl,
                  ),
                  const SizedBox(height: 16),

                  // 2. Invoice Issue Date
                  Text(
                    'Invoice Issue Date',
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
                              Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd MMMM yyyy').format(tempDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.slate400),
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
                            'Payment Terms & Due Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          Text(
                            'Optional credit period for payment',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                      if (!isNoDueDate)
                        Text(
                          DateFormat('dd MMM yyyy').format(tempDueDate!),
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
                        label: 'No Due Date',
                        isSelected: isNoDueDate,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = null;
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: 'Due on Receipt',
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
                        label: '+7 Days',
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 7,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 7));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: '+15 Days',
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 15,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 15));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: '+30 Days',
                        isSelected: tempDueDate != null &&
                            tempDueDate!.difference(tempDate).inDays == 30,
                        onTap: () {
                          setSheetState(() {
                            tempDueDate = tempDate.add(const Duration(days: 30));
                          });
                        },
                      ),
                      _buildDueDatePresetChip(
                        label: 'Custom Date...',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Changes',
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
    final nameCtrl = TextEditingController(text: _bizName);
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
              const Text(
                'Bill From (Your Business)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              CustomTextField(label: 'Business Name *', controller: nameCtrl),
              const SizedBox(height: 12),
              CustomTextField(label: 'Address', controller: addressCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: 'Phone', controller: phoneCtrl, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: 'Email', controller: emailCtrl, keyboardType: TextInputType.emailAddress)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Business Info', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    editIndex != null ? 'Edit Item' : 'Add Item',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Description *',
                    hint: 'e.g. Consulting, Design, Product',
                    controller: descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity',
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
                                icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.slate400),
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
                                icon: Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
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
                          label: 'Unit Price',
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
                            showDiscountsAndTax ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            showDiscountsAndTax ? 'Hide Item Discount & Tax' : '+ Add Item Discount & Tax',
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
                            label: 'Discount (%)',
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
                            label: 'Tax Rate (%)',
                            hint: 'Invoice rate',
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
                              Text('Base Amount:', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                              Text(CurrencyFormatter.format(baseTotal, currencySymbol: _currencySymbol), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (discountAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount (${NumberText.trim(discountPercent)}%):', style: TextStyle(fontSize: 12, color: AppColors.statusPartiallyPaid)),
                                Text('-${CurrencyFormatter.format(discountAmount, currencySymbol: _currencySymbol)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.statusPartiallyPaid)),
                              ],
                            ),
                          if (taxAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax at ${NumberText.trim(taxPercent)}% (added in totals):', style: TextStyle(fontSize: 12, color: AppColors.squircleGreenIcon)),
                                Text('+${CurrencyFormatter.format(taxAmount, currencySymbol: _currencySymbol)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.squircleGreenIcon)),
                              ],
                            ),
                          const Divider(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Line amount (before tax):', style: TextStyle(fontWeight: FontWeight.w600)),
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
                            const SnackBar(content: Text('Please enter an item description')),
                          );
                          return;
                        }
                        if (qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quantity must be more than 0')),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(editIndex != null ? 'Update Item' : 'Add to Invoice', style: const TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Add Discount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Percentage (%)')),
                      selected: tempType == DiscountType.percentage,
                      onSelected: (_) => setSheetState(() => tempType = DiscountType.percentage),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('Flat Amount ($_currencySymbol)')),
                      selected: tempType == DiscountType.flat,
                      onSelected: (_) => setSheetState(() => tempType = DiscountType.flat),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: tempType == DiscountType.percentage ? 'Discount Percentage (%)' : 'Discount Amount',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Discount', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final taxName = defaultTax.shortName;

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
                '$taxName Configuration',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                isDual
                    ? 'Choose CGST + SGST (intra-state) or IGST (inter-state)'
                    : 'Set $taxName percentage to apply to this invoice.',
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
                            ? 'No Tax (0%)'
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
                        label: const Center(child: Text('IGST (Single)')),
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
                    label: 'IGST Rate (%)',
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
                  label: '$taxName Rate (%)',
                  hint: 'e.g. ${defaultTax.rate}',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Remove Tax'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Tax', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Text('Shipping Charges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Shipping Fee ($_currencySymbol)',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Shipping Fee', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Text('Amount already received', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Amount Paid ($_currencySymbol)',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...methods.map((m) {
              final isSel = _paymentMethod == m;
              return ListTile(
                title: Text(m, style: TextStyle(fontWeight: isSel ? FontWeight.w600 : FontWeight.w500)),
                trailing: isSel ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
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
            const Text('Terms & Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Terms / Notes',
              hint: 'e.g. Thanks for your business.',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Mark Invoice As', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // Overdue is not picked: it shows automatically once the due
              // date passes with a balance left.
              ...[InvoiceStatus.unpaid, InvoiceStatus.partiallyPaid, InvoiceStatus.paid].map((s) {
                final isSel = _status == s;
                return ListTile(
                  title: Text(s.label, style: TextStyle(fontWeight: isSel ? FontWeight.w600 : FontWeight.w500)),
                  trailing: isSel ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
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
      title: 'Delete Invoice?',
      message: 'Are you sure you want to delete this invoice? This action cannot be undone.',
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
        _shippingFee, _status, _paidAmount, _currency, _signaturePath, _selectedTheme.id,
      ].join('\u0001');

  Future<void> _confirmLeave(bool didPop) async {
    if (didPop) return;
    final dirty = _initialSignature != null && _editSignature != _initialSignature;
    if (dirty) {
      final discard = await AppDialog.showConfirmation(
        context: context,
        title: 'Discard changes?',
        message: 'You have unsaved changes. Leave without saving them?',
        variant: AppDialogVariant.danger,
        icon: Icons.warning_amber_rounded,
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
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
    final taxShortName = currencyProvider.defaultTax.shortName;
    final currencySymbol = _currencySymbol;

    // Sequential coachmarks state evaluation
    final bool hasClient = _clientNameCtrl.text.trim().isNotEmpty && _clientNameCtrl.text.trim() != 'Add Clients';
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
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
            // maybePop, so the unsaved-changes check runs.
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.existingInvoice != null ? 'Edit Invoice' : 'Create Invoice',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3),
          ),
          centerTitle: true,
          actions: [
            if (!isPro)
              IconButton(
                icon: Icon(Icons.workspace_premium_rounded, color: AppColors.proGold),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.ink, size: 20),
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
                  title: 'Clear Items',
                  icon: Icons.clear_all_rounded,
                  iconColor: AppColors.muted,
                ),
                AppPopupMenuItem.item(
                  value: 'reset_tips',
                  title: 'Reset Helpful Tips',
                  icon: Icons.lightbulb_outline_rounded,
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
                                      'INVOICE',
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
                              Icon(Icons.edit_outlined, size: 18, color: AppColors.muted),
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
                                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd MMM yyyy').format(_invoiceDate),
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
                                        Icons.hourglass_bottom_rounded,
                                        size: 13,
                                        color: _dueDate != null
                                            ? AppColors.statusPartiallyPaid
                                            : AppColors.slate400,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _dueDate != null
                                              ? 'Due ${DateFormat('dd MMM').format(_dueDate!)}'
                                              : 'No Due Date',
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
                          if (selected != null && mounted) {
                            setState(() {
                              _selectedTheme = selected.theme;
                              _customDesign = selected.customConfig;
                            });
                          }
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
                                Icons.view_quilt_outlined,
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
                                    'Templates',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Choose style & paper design',
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
                            Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                                  child: Icon(Icons.storefront_outlined, color: AppColors.squircleCyanIcon, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bill From', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(
                                        _bizName.isNotEmpty ? _bizName : 'Add Business',
                                        style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                                  child: Icon(Icons.people_outline_rounded, color: AppColors.statusPartiallyPaid, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bill To', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(
                                        _clientNameCtrl.text.isNotEmpty ? _clientNameCtrl.text : 'Add Clients',
                                        style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
                              ],
                            ),
                          ),

                          // Sequential Coachmark 1: Add Client
                          if (showClientTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: 'Step 1 of 4',
                              title: 'Add your client or customer',
                              subtitle: 'Select an existing client or create a new one to bill',
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
                                child: Icon(Icons.inventory_2_outlined, color: AppColors.squircleGreenIcon, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text(
                                      _items.isEmpty ? 'Add Items' : '${_items.length} item(s) added',
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
                                  child: Icon(Icons.inventory_2_outlined, color: AppColors.squirclePurpleIcon, size: 18),
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
                                  child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),

                          // Sequential Coachmark 2: Add Items
                          if (showItemsTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: 'Step 2 of 4',
                              title: 'Create your item or service',
                              subtitle: 'Add name, price, quantity and details',
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
                                  child: Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 20),
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
                                        icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.slate500),
                                        onPressed: () => _showAddItemSheet(editIndex: idx),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded, size: 18, color: AppColors.accentRed),
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
                            icon: Icons.percent_rounded,
                            title: 'Discount',
                            subtitle: _hasDiscount ? '(${_discountCtrl.text}${_discountType == DiscountType.percentage ? "%" : ""})' : '(0%)',
                            value: _hasDiscount
                                ? '-${CurrencyFormatter.format(_discountAmount, currencyCode: _currency, currencySymbol: currencySymbol)}'
                                : '-$currencySymbol 0.00',
                            onTap: _showDiscountSheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: Icons.account_balance_outlined,
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
                            icon: Icons.local_shipping_outlined,
                            title: 'Shipping',
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
                                Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                              stepLabel: 'Step 3 of 4',
                              title: 'Configure discount, tax or shipping',
                              subtitle: 'Apply $taxShortName rates, discounts or shipping charges',
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
                            icon: Icons.monetization_on_outlined,
                            title: 'Payments',
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
                                Text('Balance Due', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                            icon: Icons.payments_outlined,
                            title: 'Currency',
                            subtitle: '',
                            value: '$_currency $_currencySymbol',
                            onTap: _showCurrencySheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: Icons.credit_card_outlined,
                            title: 'Payment Method',
                            subtitle: '',
                            value: _paymentMethod.isNotEmpty ? _paymentMethod : '',
                            onTap: _showPaymentMethodSheet,
                          ),
                          const Divider(height: 16),
                          _buildRowTile(
                            icon: Icons.draw_outlined,
                            title: 'Signature',
                            subtitle: '',
                            value: _signaturePath != null ? 'Signature Attached' : 'Add Signature',
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
                            icon: Icons.assignment_outlined,
                            title: 'Terms Or Notes',
                            subtitle: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : 'Thanks for your business.',
                            value: '',
                            onTap: _showNotesSheet,
                          ),

                          // Sequential Coachmark 4: Payment Method & Signature
                          if (showSettingsTip) ...[
                            _buildCoachmarkBalloon(
                              stepLabel: 'Step 4 of 4',
                              title: 'Set payment method & signature',
                              subtitle: 'Add UPI, bank details, notes or your signature',
                              onTap: _showPaymentMethodSheet,
                              onDismiss: () => _dismissTip('settings'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 8: Attachments
                    _buildCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.attach_file_rounded, color: AppColors.slate700, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Attachments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text(
                                  _attachments.isEmpty ? 'Add attachments' : '${_attachments.length} attached',
                                  style: TextStyle(fontSize: 13, color: AppColors.slate500),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(source: ImageSource.gallery);
                              if (img != null) {
                                setState(() => _attachments.add(img.path));
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 9: Status & Stamp Toggle
                    _buildCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildRowTile(
                            icon: Icons.fact_check_outlined,
                            title: 'Mark as',
                            subtitle: '',
                            value: _status.label,
                            onTap: _showStatusSheet,
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.verified_outlined, size: 18, color: AppColors.slate700),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Show 'PAID' Stamp on Invoice",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Switch.adaptive(
                                value: _showPaidStamp,
                                activeTrackColor: AppColors.primary,
                                onChanged: (v) => setState(() => _showPaidStamp = v),
                              ),
                            ],
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
                            Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delete Invoice',
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
                      onPressed: _handlePreview,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.hairline, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                      ),
                      child: Text(
                        'Preview',
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
                      onPressed: _isSaving ? null : _handleSaveAndOpenPreview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                            )
                          : Text(
                              'Save',
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
                      color: Colors.white,
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
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded, color: Color(0xFF888888), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: const Color(0xFFAAAAAA), fontSize: 12),
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
          Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}
