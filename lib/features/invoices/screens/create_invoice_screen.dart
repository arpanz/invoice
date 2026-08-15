import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../clients/models/client_model.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../widgets/pdf_theme_picker_sheet.dart';
import 'invoice_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? existingInvoice;

  const CreateInvoiceScreen({super.key, this.existingInvoice});

  static Future<bool> canCreateNewInvoice(BuildContext context) async {
    final isPro = context.read<BillingService>().isPro;
    if (isPro) return true;

    final count = await DbProvider.countInvoicesThisMonth();
    if (count >= 10) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
      }
      return false;
    }
    return true;
  }

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _scrollController = ScrollController();

  // Invoice Number & Dates
  final _invoiceNumberCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _dueDatePreset = 'Net 7';

  // Business (Bill From)
  String _bizName = 'My Business';
  String? _bizAddress;
  String? _bizPhone;
  String? _bizEmail;
  String? _bizGstin;

  // Client (Bill To)
  ClientModel? _selectedClient;
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

    final savedThemeId = widget.existingInvoice != null
        ? (prefs.getString('invoice_theme_${widget.existingInvoice!.id}') ??
            prefs.getString('default_pdf_theme'))
        : prefs.getString('default_pdf_theme');
    if (savedThemeId != null) {
      _selectedTheme = PdfTheme.fromId(savedThemeId);
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
      _notesCtrl.text = inv.notes ?? 'Thanks for your business.';
      _status = inv.status;

      _items.addAll(inv.lineItems);

      if (inv.discountType != DiscountType.none && inv.discountValue > 0) {
        _hasDiscount = true;
        _discountType = inv.discountType;
        _discountCtrl.text = inv.discountValue.toString();
      }

      if (inv.sgstRate > 0 || inv.cgstRate > 0 || inv.igstRate > 0) {
        _hasTax = true;
        if (inv.igstRate > 0) {
          _useIGST = true;
          _igstCtrl.text = inv.igstRate.toString();
        } else {
          _sgstCtrl.text = inv.sgstRate.toString();
          _cgstCtrl.text = inv.cgstRate.toString();
        }
      }
    } else {
      // New Invoice
      final invoiceCount = await _getNextInvoiceNumber();
      _invoiceNumberCtrl.text = 'INV${invoiceCount.toString().padLeft(5, '0')}';
      _dueDate = _invoiceDate.add(const Duration(days: 7));

      if (defaultTax > 0) {
        _hasTax = true;
        if (currencyProvider.isDualTax) {
          final half = defaultTax / 2;
          _sgstCtrl.text = half.toStringAsFixed(1).replaceAll('.0', '');
          _cgstCtrl.text = half.toStringAsFixed(1).replaceAll('.0', '');
        } else {
          _useIGST = true;
          _igstCtrl.text = defaultTax.toStringAsFixed(1).replaceAll('.0', '');
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _dismissTip(String tipKey) async {
    setState(() => _dismissedTips.add(tipKey));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_invoice_tips', _dismissedTips.toList());
  }

  Future<int> _getNextInvoiceNumber() async {
    final rows = await DbProvider.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbProvider.tableInvoices}',
    );
    return (rows.first['count'] as int) + 1;
  }

  // Calculations
  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  double get _discountAmount {
    if (!_hasDiscount) return 0;
    final value = double.tryParse(_discountCtrl.text) ?? 0;
    if (_discountType == DiscountType.percentage) {
      return _subtotal * value / 100;
    }
    return value;
  }

  double get _taxableAmount => (_subtotal - _discountAmount).clamp(0, double.infinity);

  double get _taxAmount {
    if (!_hasTax) return 0;
    if (_useIGST) {
      final rate = double.tryParse(_igstCtrl.text) ?? 0;
      return _taxableAmount * rate / 100;
    } else {
      final sgst = double.tryParse(_sgstCtrl.text) ?? 0;
      final cgst = double.tryParse(_cgstCtrl.text) ?? 0;
      return _taxableAmount * (sgst + cgst) / 100;
    }
  }

  double get _grandTotal => _taxableAmount + _taxAmount + _shippingFee;
  double get _balanceDue => (_grandTotal - _paidAmount).clamp(0, double.infinity);

  String get _currencySymbol => CurrencyFormatter.getCurrencySymbol(_currency);

  InvoiceModel _buildInvoiceModel() {
    final now = DateTime.now();
    final invoiceId = _activeInvoiceId ?? const Uuid().v4();
    _activeInvoiceId = invoiceId;

    final lineItems = _items.asMap().entries.map((e) {
      return LineItemModel(
        id: e.value.id.isEmpty ? 'li-${now.microsecondsSinceEpoch}-${e.key}' : e.value.id,
        invoiceId: invoiceId,
        description: e.value.description,
        quantity: e.value.quantity,
        unitPrice: e.value.unitPrice,
        total: e.value.total,
        sortOrder: e.key,
      );
    }).toList();

    return InvoiceModel(
      id: invoiceId,
      invoiceNumber: _invoiceNumberCtrl.text.trim().isEmpty
          ? 'INV00001'
          : _invoiceNumberCtrl.text.trim(),
      clientId: _selectedClient?.id,
      clientName: _clientNameCtrl.text.trim().isEmpty
          ? 'Add Client'
          : _clientNameCtrl.text.trim(),
      clientEmail: _clientEmailCtrl.text.trim().isEmpty ? null : _clientEmailCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim().isEmpty ? null : _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim().isEmpty ? null : _clientAddressCtrl.text.trim(),
      clientGstin: _clientGstinCtrl.text.trim().isEmpty ? null : _clientGstinCtrl.text.trim(),
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      subtotal: _subtotal,
      discountType: _hasDiscount ? _discountType : DiscountType.none,
      discountValue: _hasDiscount ? (double.tryParse(_discountCtrl.text) ?? 0) : 0,
      discountAmount: _discountAmount,
      sgstRate: (!_hasTax || _useIGST) ? 0 : (double.tryParse(_sgstCtrl.text) ?? 0),
      cgstRate: (!_hasTax || _useIGST) ? 0 : (double.tryParse(_cgstCtrl.text) ?? 0),
      igstRate: (_hasTax && _useIGST) ? (double.tryParse(_igstCtrl.text) ?? 0) : 0,
      taxAmount: _taxAmount,
      grandTotal: _grandTotal,
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currency: _currency,
      createdAt: widget.existingInvoice?.createdAt ?? now,
      updatedAt: now,
      lineItems: lineItems,
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

    setState(() => _isSaving = true);
    try {
      final invoice = _buildInvoiceModel();

      await DbProvider.insert(DbProvider.tableInvoices, invoice.toMap());
      await DbProvider.delete(DbProvider.tableLineItems, 'invoice_id = ?', [invoice.id]);

      for (final item in invoice.lineItems) {
        await DbProvider.insert(DbProvider.tableLineItems, item.toMap());
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('invoice_theme_${invoice.id}', _selectedTheme.id.value);

      setState(() => _isSaving = false);
      return invoice;
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _handlePreview() async {
    final invoice = _buildInvoiceModel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoice_theme_${invoice.id}', _selectedTheme.id.value);
    if (!mounted) return;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final dueFormatted = tempDueDate != null
              ? DateFormat('dd/MM/yyyy').format(tempDueDate!)
              : 'None';

          return Padding(
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
                const Text(
                  'Invoice Info & Dates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Invoice Number',
                  hint: 'e.g. INV00001',
                  controller: numCtrl,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tempDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setSheetState(() => tempDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Invoice Date', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd/MM/yyyy').format(tempDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: tempDueDate ?? tempDate.add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setSheetState(() => tempDueDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.cardBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due Date', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                              const SizedBox(height: 4),
                              Text(dueFormatted, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: ['Net 7', 'Net 15', 'Net 30', 'Due on Receipt'].map((preset) {
                    final isSel = _dueDatePreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSel,
                      onSelected: (sel) {
                        if (sel) {
                          setSheetState(() {
                            _dueDatePreset = preset;
                            if (preset == 'Net 7') tempDueDate = tempDate.add(const Duration(days: 7));
                            if (preset == 'Net 15') tempDueDate = tempDate.add(const Duration(days: 15));
                            if (preset == 'Net 30') tempDueDate = tempDate.add(const Duration(days: 30));
                            if (preset == 'Due on Receipt') tempDueDate = tempDate;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _invoiceNumberCtrl.text = numCtrl.text.trim();
                        _invoiceDate = tempDate;
                        _dueDate = tempDueDate;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Business Info', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final qtyCtrl = TextEditingController(text: item != null ? item.quantity.toString().replaceAll('.0', '') : '1');
    final priceCtrl = TextEditingController(text: item != null ? item.unitPrice.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final qty = double.tryParse(qtyCtrl.text) ?? 1;
          final price = double.tryParse(priceCtrl.text) ?? 0;
          final total = qty * price;

          return Padding(
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
                  editIndex != null ? 'Edit Item' : 'Add Item',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        CurrencyFormatter.format(total, currencySymbol: _currencySymbol),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
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
                      final q = double.tryParse(qtyCtrl.text) ?? 1;
                      final p = double.tryParse(priceCtrl.text) ?? 0;
                      final newItem = LineItemModel(
                        id: item?.id ?? const Uuid().v4(),
                        invoiceId: _activeInvoiceId ?? '',
                        description: descCtrl.text.trim(),
                        quantity: q,
                        unitPrice: p,
                        total: q * p,
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
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(editIndex != null ? 'Update Item' : 'Add to Invoice', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Text('Add Discount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    final val = double.tryParse(valCtrl.text) ?? 0;
                    setState(() {
                      _hasDiscount = val > 0;
                      _discountType = tempType;
                      _discountCtrl.text = valCtrl.text;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Discount', style: TextStyle(fontWeight: FontWeight.w700)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                isDual
                    ? 'Choose CGST + SGST (intra-state) or IGST (inter-state)'
                    : 'Set $taxName percentage to apply to this invoice.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                            : '$taxName ${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPresetSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isPresetSelected ? AppColors.primary : AppColors.slate100,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setSheetState(() {
                          if (isDual && !useIGST) {
                            final half = rate / 2;
                            sgstCtrl.text = half.toStringAsFixed(half % 1 == 0 ? 0 : 1);
                            cgstCtrl.text = half.toStringAsFixed(half % 1 == 0 ? 0 : 1);
                          } else {
                            igstCtrl.text = rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1);
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
                            sgstCtrl.text = half.toStringAsFixed(half % 1 == 0 ? 0 : 1);
                            cgstCtrl.text = half.toStringAsFixed(half % 1 == 0 ? 0 : 1);
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
                            final total = (double.tryParse(sgstCtrl.text) ?? 0) + (double.tryParse(cgstCtrl.text) ?? 0);
                            igstCtrl.text = (total > 0 ? total : defaultTax.rate).toStringAsFixed(1).replaceAll('.0', '');
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
                              ? (double.tryParse(sgstCtrl.text) ?? 0) + (double.tryParse(cgstCtrl.text) ?? 0)
                              : (double.tryParse(igstCtrl.text) ?? 0);
                          _hasTax = totalTax > 0;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Tax', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final ctrl = TextEditingController(text: _shippingFee > 0 ? _shippingFee.toString() : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
            const Text('Shipping Charges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  setState(() => _shippingFee = double.tryParse(ctrl.text) ?? 0.0);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Shipping Fee', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentsSheet() {
    final ctrl = TextEditingController(text: _paidAmount > 0 ? _paidAmount.toString() : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
            const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  final p = double.tryParse(ctrl.text) ?? 0.0;
                  setState(() {
                    _paidAmount = p;
                    if (_paidAmount >= _grandTotal && _grandTotal > 0) {
                      _status = InvoiceStatus.paid;
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet() {
    final supported = ['INR', 'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'AED', 'SGD', 'JPY'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...supported.map((c) {
              final symbol = CurrencyFormatter.getCurrencySymbol(c);
              final isSel = _currency == c;
              return ListTile(
                title: Text('$c ($symbol)', style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSel ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _currency = c);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodSheet() {
    final methods = ['Bank Transfer / NEFT', 'UPI / GPay / PhonePe', 'Cash', 'Credit / Debit Card', 'Cheque', 'PayPal'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...methods.map((m) {
              final isSel = _paymentMethod == m;
              return ListTile(
                title: Text(m, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSel ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
            const Text('Terms & Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.w700)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Mark Invoice As', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...[InvoiceStatus.unpaid, InvoiceStatus.paid, InvoiceStatus.overdue].map((s) {
                final isSel = _status == s;
                return ListTile(
                  title: Text(s.label, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                  trailing: isSel ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _status = s);
                    Navigator.pop(ctx);
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _activeInvoiceId != null) {
      await DbProvider.delete(DbProvider.tableInvoices, 'id = ?', [_activeInvoiceId]);
      await PdfHelper.deletePdf(_invoiceNumberCtrl.text);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDual = currencyProvider.isDualTax;
    final taxShortName = currencyProvider.defaultTax.shortName;
    final currencySymbol = _currencySymbol;
    final dueDateFormatted = _dueDate != null
        ? DateFormat('dd/MM/yyyy').format(_dueDate!)
        : DateFormat('dd/MM/yyyy').format(_invoiceDate);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingInvoice != null ? 'Edit Invoice' : 'Create Invoice',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (!isPro)
            IconButton(
              icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.proGold),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onSelected: (val) async {
              if (val == 'clear') {
                setState(() {
                  _items.clear();
                  _clientNameCtrl.clear();
                });
              } else if (val == 'reset_tips') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('dismissed_invoice_tips');
                setState(() => _dismissedTips.clear());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Items')),
              const PopupMenuItem(value: 'reset_tips', child: Text('Reset Helpful Tips')),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _invoiceNumberCtrl.text.isNotEmpty ? _invoiceNumberCtrl.text : 'INV00001',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text('Due on $dueDateFormatted', style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                          ],
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                            _selectedTheme = selected;
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
                              borderRadius: BorderRadius.circular(10),
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
                                const Text(
                                  'Templates',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedTheme.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedTheme.previewPrimary,
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
                          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F2FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_outlined, color: Color(0xFF0284C7), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bill From', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                    Text(
                                      _bizName.isNotEmpty ? _bizName : 'Add Business',
                                      style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline_rounded, color: Color(0xFFD97706), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bill To', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                    Text(
                                      _clientNameCtrl.text.isNotEmpty ? _clientNameCtrl.text : 'Add Clients',
                                      style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  Text(
                                    _items.isEmpty ? 'Add Items' : '${_items.length} item(s) added',
                                    style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAddItemSheet(),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(
                                          '${item.quantity.toString().replaceAll(".0", "")} x ${CurrencyFormatter.format(item.unitPrice, currencySymbol: _currencySymbol)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(item.total, currencySymbol: _currencySymbol),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slate500),
                                    onPressed: () => _showAddItemSheet(editIndex: idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.accentRed),
                                    onPressed: () => setState(() => _items.removeAt(idx)),
                                  ),
                                ],
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
                          value: _hasDiscount ? '-$currencySymbol${_discountAmount.toStringAsFixed(2)}' : '-$currencySymbol 0.00',
                          onTap: _showDiscountSheet,
                        ),
                        const Divider(height: 16),
                        _buildRowTile(
                          icon: Icons.account_balance_outlined,
                          title: taxShortName,
                          subtitle: _hasTax
                              ? (isDual && !_useIGST
                                  ? '(CGST ${_cgstCtrl.text}% + SGST ${_sgstCtrl.text}%)'
                                  : '(${_useIGST ? _igstCtrl.text : ((double.tryParse(_sgstCtrl.text) ?? 0) + (double.tryParse(_cgstCtrl.text) ?? 0)).toStringAsFixed(1).replaceAll('.0', '')}%)')
                              : '(0%)',
                          value: '$currencySymbol${_taxAmount.toStringAsFixed(2)}',
                          onTap: _showTaxSheet,
                        ),
                        const Divider(height: 16),
                        _buildRowTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Shipping',
                          subtitle: '',
                          value: '$currencySymbol${_shippingFee.toStringAsFixed(2)}',
                          onTap: _showShippingSheet,
                        ),
                        const SizedBox(height: 12),
                        // Total Row Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text(
                                '$currencySymbol${_grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
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
                          value: '$currencySymbol${_paidAmount.toStringAsFixed(2)}',
                          onTap: _showPaymentsSheet,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Balance Due', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text(
                                '$currencySymbol${_balanceDue.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
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
                              setState(() => _signaturePath = img.path);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('biz_signature_path', img.path);
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.attach_file_rounded, color: AppColors.slate700, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Attachments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              Text(
                                _attachments.isEmpty ? 'Add attachments' : '${_attachments.length} attached',
                                style: const TextStyle(fontSize: 13, color: AppColors.slate500),
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
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
                              child: const Icon(Icons.verified_outlined, size: 18, color: AppColors.slate700),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete Invoice',
                            style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700, fontSize: 15),
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

      // Sticky Bottom Bar with [Preview] and [Save] matching screenshots
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handlePreview,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveAndOpenPreview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stepLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
                    child: Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.slate700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (value.isNotEmpty) ...[
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
        ],
      ),
    );
  }
}
