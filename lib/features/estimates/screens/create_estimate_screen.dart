import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/currency_picker_sheet.dart';
import '../../clients/models/client_model.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/widgets/pdf_theme_picker_sheet.dart';
import '../../paywall/paywall_screen.dart';
import '../../items/screens/item_picker_sheet.dart';
import '../models/estimate_model.dart';
import 'estimate_preview_screen.dart';

class CreateEstimateScreen extends StatefulWidget {
  final EstimateModel? existingEstimate;

  const CreateEstimateScreen({super.key, this.existingEstimate});

  static Future<bool> canCreateNewEstimate(BuildContext context) async {
    final isPro = context.read<BillingService>().isPro;
    if (isPro) return true;

    final count = await DbProvider.countEstimatesThisMonth();
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
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  final _scrollController = ScrollController();

  // Estimate Number & Dates
  final _estimateNumberCtrl = TextEditingController();
  DateTime _estimateDate = DateTime.now();
  DateTime? _expiryDate;

  // Business Profile
  String _bizName = 'My Business';

  // Client Details
  ClientModel? _selectedClient;
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
  final _notesCtrl = TextEditingController(
    text: 'This estimate is valid for 30 days. Contact us to accept.',
  );
  PdfTheme _selectedTheme = PdfTheme.defaultTheme;
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
    final prefs = await SharedPreferences.getInstance();
    final currencyProvider = context.read<CurrencyProvider>();

    _bizName = prefs.getString('biz_name') ?? 'My Business';

    final savedThemeId = prefs.getString('default_pdf_theme');
    if (savedThemeId != null) {
      _selectedTheme = PdfTheme.fromId(savedThemeId);
    }

    if (widget.existingEstimate != null) {
      final e = widget.existingEstimate!;
      _activeEstimateId = e.id;
      _estimateNumberCtrl.text = e.estimateNumber;
      _estimateDate = e.estimateDate;
      _expiryDate = e.expiryDate;
      _clientNameCtrl.text = e.clientName;
      _clientEmailCtrl.text = e.clientEmail ?? '';
      _clientPhoneCtrl.text = e.clientPhone ?? '';
      _clientAddressCtrl.text = e.clientAddress ?? '';
      _clientGstinCtrl.text = e.clientGstin ?? '';
      _items.addAll(e.lineItems);

      _hasDiscount = e.discountType != DiscountType.none && e.discountValue > 0;
      _discountType = e.discountType;
      _discountCtrl.text = e.discountValue.toStringAsFixed(0);

      _hasTax = (e.sgstRate + e.cgstRate + e.igstRate) > 0;
      _useIGST = e.igstRate > 0;
      _sgstCtrl.text = e.sgstRate.toStringAsFixed(0);
      _cgstCtrl.text = e.cgstRate.toStringAsFixed(0);
      _igstCtrl.text = e.igstRate.toStringAsFixed(0);

      _notesCtrl.text = e.notes ?? '';
      _currency = e.currency;
      _status = e.status;
    } else {
      _activeEstimateId = const Uuid().v4();
      final nextNum = await DbProvider.getNextEstimateNumber();
      _estimateNumberCtrl.text = nextNum;
      _currency = currencyProvider.currencyCode;
      _expiryDate = DateTime.now().add(const Duration(days: 30));

      final taxCfg = currencyProvider.selectedCurrency.defaultTax;
      if (taxCfg.isDualTax) {
        final half = taxCfg.rate / 2;
        _sgstCtrl.text = half.toStringAsFixed(0);
        _cgstCtrl.text = half.toStringAsFixed(0);
        _igstCtrl.text = taxCfg.rate.toStringAsFixed(0);
      } else {
        _igstCtrl.text = taxCfg.rate.toStringAsFixed(0);
        _useIGST = true;
      }
    }

    if (mounted) setState(() {});
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  double get _discountAmount {
    if (!_hasDiscount) return 0.0;
    final val = double.tryParse(_discountCtrl.text) ?? 0.0;
    if (_discountType == DiscountType.percentage) {
      return _subtotal * (val / 100);
    }
    return val;
  }

  double get _taxableAmount =>
      (_subtotal - _discountAmount).clamp(0.0, double.infinity);

  double get _taxAmount {
    if (!_hasTax) return 0.0;
    if (_useIGST) {
      final rate = double.tryParse(_igstCtrl.text) ?? 0.0;
      return _taxableAmount * (rate / 100);
    } else {
      final sgst = double.tryParse(_sgstCtrl.text) ?? 0.0;
      final cgst = double.tryParse(_cgstCtrl.text) ?? 0.0;
      return _taxableAmount * ((sgst + cgst) / 100);
    }
  }

  double get _grandTotal => _taxableAmount + _taxAmount;

  EstimateModel _buildEstimateModel() {
    final now = DateTime.now();
    return EstimateModel(
      id: _activeEstimateId ?? const Uuid().v4(),
      estimateNumber: _estimateNumberCtrl.text.trim().isEmpty
          ? 'EST00001'
          : _estimateNumberCtrl.text.trim(),
      clientId: _selectedClient?.id,
      clientName: _clientNameCtrl.text.trim().isEmpty
          ? 'Valued Client'
          : _clientNameCtrl.text.trim(),
      clientEmail: _clientEmailCtrl.text.trim().isEmpty
          ? null
          : _clientEmailCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim().isEmpty
          ? null
          : _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim().isEmpty
          ? null
          : _clientAddressCtrl.text.trim(),
      clientGstin: _clientGstinCtrl.text.trim().isEmpty
          ? null
          : _clientGstinCtrl.text.trim(),
      estimateDate: _estimateDate,
      expiryDate: _expiryDate,
      subtotal: _subtotal,
      discountType: _hasDiscount ? _discountType : DiscountType.none,
      discountValue: _hasDiscount
          ? (double.tryParse(_discountCtrl.text) ?? 0)
          : 0,
      discountAmount: _discountAmount,
      sgstRate: _hasTax && !_useIGST
          ? (double.tryParse(_sgstCtrl.text) ?? 0)
          : 0,
      cgstRate: _hasTax && !_useIGST
          ? (double.tryParse(_cgstCtrl.text) ?? 0)
          : 0,
      igstRate: _hasTax && _useIGST
          ? (double.tryParse(_igstCtrl.text) ?? 0)
          : 0,
      taxAmount: _taxAmount,
      grandTotal: _grandTotal,
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      currency: _currency,
      createdAt: widget.existingEstimate?.createdAt ?? now,
      updatedAt: now,
      lineItems: _items,
    );
  }

  Future<void> _saveEstimate({bool popAfter = true}) async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a client name')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final estimate = _buildEstimateModel();

      // Upsert Estimate
      final existing = await DbProvider.query(
        DbProvider.tableEstimates,
        where: 'id = ?',
        whereArgs: [estimate.id],
      );

      if (existing.isEmpty) {
        await DbProvider.insert(DbProvider.tableEstimates, estimate.toMap());
      } else {
        await DbProvider.update(
          DbProvider.tableEstimates,
          estimate.toMap(),
          'id = ?',
          [estimate.id],
        );
      }

      // Upsert Line Items
      await DbProvider.delete(
        DbProvider.tableEstimateLineItems,
        'estimate_id = ?',
        [estimate.id],
      );

      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        await DbProvider.insert(DbProvider.tableEstimateLineItems, {
          'id': item.id,
          'estimate_id': estimate.id,
          'description': item.description,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'sort_order': i,
        });
      }

      // Save theme preference for this estimate
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'estimate_theme_${estimate.id}',
        _selectedTheme.id.name,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (popAfter) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save estimate: $e')));
      }
    }
  }

  Future<void> _openPreview() async {
    final estimate = _buildEstimateModel();
    await _saveEstimate(popAfter: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimatePreviewScreen(estimate: estimate),
      ),
    );
  }

  void _showItemDialog({LineItemModel? existingItem, int? index}) {
    final descCtrl = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: existingItem != null ? existingItem.quantity.toString() : '1',
    );
    final priceCtrl = TextEditingController(
      text: existingItem != null
          ? existingItem.unitPrice.toStringAsFixed(2)
          : '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    borderRadius: BorderRadius.circular(99),
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
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.squircleGreenIcon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingItem == null ? 'Add Item / Service' : 'Edit Item',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Enter description, quantity & rate',
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
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description / Item Name *',
                hint: 'e.g. Website Design, Consultation, Parts',
                controller: descCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Quantity *',
                      hint: '1',
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = double.tryParse(v ?? '');
                        if (parsed == null || parsed <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Unit Price *',
                      hint: '0.00',
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText:
                          '${CurrencyFormatter.getCurrencySymbol(_currency)} ',
                      validator: (v) {
                        final parsed = double.tryParse(v ?? '');
                        if (parsed == null || parsed < 0) return 'Invalid';
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                      final price =
                          double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      final total = qty * price;

                      setState(() {
                        if (existingItem != null && index != null) {
                          _items[index] = LineItemModel(
                            id: existingItem.id,
                            invoiceId: existingItem.invoiceId,
                            description: descCtrl.text.trim(),
                            quantity: qty,
                            unitPrice: price,
                            total: total,
                            sortOrder: index,
                          );
                        } else {
                          _items.add(
                            LineItemModel(
                              id: const Uuid().v4(),
                              invoiceId: _activeEstimateId ?? '',
                              description: descCtrl.text.trim(),
                              quantity: qty,
                              unitPrice: price,
                              total: total,
                              sortOrder: _items.length,
                            ),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    existingItem == null ? 'Add to Estimate' : 'Save Changes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
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
    if (chosen != null) {
      setState(() => _selectedTheme = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingEstimate != null ? 'Edit Estimate' : 'Create Estimate',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'PDF Templates',
            icon: const Icon(Icons.palette_outlined, color: AppColors.primary),
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
                          label: 'Estimate Number *',
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
                            decoration: const InputDecoration(
                              labelText: 'Estimate Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_estimateDate),
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
                            decoration: const InputDecoration(
                              labelText: 'Valid Until / Expiry',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _expiryDate != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_expiryDate!)
                                  : 'No Expiry',
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
                      const Text(
                        'Quick Validity: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                      _buildQuickDateChip('7 Days', 7),
                      const SizedBox(width: 6),
                      _buildQuickDateChip('14 Days', 14),
                      const SizedBox(width: 6),
                      _buildQuickDateChip('30 Days', 30),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF Theme',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _selectedTheme.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Bill From',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                    subtitle: Text(
                      _bizName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bill To (Client) *',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                            Text(
                              _clientNameCtrl.text.isEmpty
                                  ? 'Select / Add Client'
                                  : _clientNameCtrl.text,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
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
                        tooltip: 'Select Client',
                        icon: const Icon(
                          Icons.contacts_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: _pickClient,
                      ),
                    ],
                  ),
                  if (_selectedClient == null) ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Client Name *',
                      hint: 'John Doe / Apex Corp',
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
                      const Text(
                        'Items & Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                            label: const Text('Catalog'),
                            onPressed: () async {
                              final picked = await ItemPickerSheet.show(
                                context,
                                invoiceId: _activeEstimateId ?? '',
                              );
                              if (picked != null && picked.isNotEmpty) {
                                setState(() => _items.addAll(picked));
                              }
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Item'),
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
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: AppColors.slate300,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No items added yet',
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity.toString().replaceAll(".0", "")} x ${CurrencyFormatter.format(item.unitPrice, currencyCode: _currency, currencySymbol: currencySymbol)}',
                                    style: const TextStyle(
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
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.slate400,
                              ),
                              onPressed: () =>
                                  _showItemDialog(existingItem: item, index: i),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
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
                    'Subtotal',
                    CurrencyFormatter.format(_subtotal, currencyCode: _currency, currencySymbol: currencySymbol),
                  ),
                  const SizedBox(height: 8),

                  // Discount switch & inputs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount',
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
                      'Discount Amount',
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
                            : 'Tax',
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
                            '${currencyProvider.selectedCurrency.defaultTax.shortName} %',
                        controller: _igstCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Tax Amount',
                      '+${CurrencyFormatter.format(_taxAmount, currencyCode: _currency, currencySymbol: currencySymbol)}',
                    ),
                  ],
                  const Divider(height: 24),

                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_grandTotal, currencyCode: _currency, currencySymbol: currencySymbol),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Currency',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$_currency $currencySymbol',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.slate400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7. Notes & Terms Card
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes & Terms',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    hint: 'e.g. Estimate valid for 30 days. Payment terms...',
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _openPreview,
                  child: const Text(
                    'Preview PDF',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => _saveEstimate(popAfter: true),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Estimate',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
          color: Colors.white,
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
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.slate600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isNegative ? AppColors.statusOverdue : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
