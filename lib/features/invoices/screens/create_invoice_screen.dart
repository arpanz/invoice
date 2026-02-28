import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../clients/models/client_model.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../settings/screens/business_profile_screen.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../services/pdf_generator_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? existingInvoice;

  const CreateInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Invoice Details
  final _invoiceNumberCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  String _dueDatePreset = 'Net 30';

  // Client
  ClientModel? _selectedClient;
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientGstinCtrl = TextEditingController();

  // Line Items
  final List<_LineItemEntry> _lineItems = [];

  // Financials
  bool _hasDiscount = false;
  DiscountType _discountType = DiscountType.percentage;
  final _discountCtrl = TextEditingController(text: '0');

  bool _hasTax = false;
  bool _useIGST = false;
  final _sgstCtrl = TextEditingController(text: '9');
  final _cgstCtrl = TextEditingController(text: '9');
  final _igstCtrl = TextEditingController(text: '18');

  final _notesCtrl = TextEditingController();
  String _currency = 'INR';

  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('default_currency') ?? 'INR';
    final defaultTax = prefs.getDouble('default_tax_rate') ?? 18.0;

    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _invoiceNumberCtrl.text = inv.invoiceNumber;
      _invoiceDate = inv.invoiceDate;
      _dueDate = inv.dueDate;
      _clientNameCtrl.text = inv.clientName;
      _clientEmailCtrl.text = inv.clientEmail ?? '';
      _clientPhoneCtrl.text = inv.clientPhone ?? '';
      _clientAddressCtrl.text = inv.clientAddress ?? '';
      _clientGstinCtrl.text = inv.clientGstin ?? '';
      _currency = inv.currency;
      _notesCtrl.text = inv.notes ?? '';

      for (final item in inv.lineItems) {
        _lineItems.add(_LineItemEntry(
          id: item.id,
          descCtrl: TextEditingController(text: item.description),
          qtyCtrl: TextEditingController(text: item.quantity.toString()),
          priceCtrl: TextEditingController(text: item.unitPrice.toString()),
        ));
      }

      if (inv.discountType != DiscountType.none) {
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
      // New invoice
      final invoiceCount = await _getNextInvoiceNumber();
      _invoiceNumberCtrl.text = 'INV-${invoiceCount.toString().padLeft(3, '0')}';
      _dueDate = DateTime.now().add(const Duration(days: 30));

      if (defaultTax > 0) {
        _hasTax = true;
        final half = defaultTax / 2;
        _sgstCtrl.text = half.toStringAsFixed(0);
        _cgstCtrl.text = half.toStringAsFixed(0);
      }

      // Add one empty line item
      _lineItems.add(_LineItemEntry.empty());
    }

    setState(() {});
  }

  Future<int> _getNextInvoiceNumber() async {
    final rows = await DbProvider.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbProvider.tableInvoices}',
    );
    return (rows.first['count'] as int) + 1;
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _discountAmount {
    if (!_hasDiscount) return 0;
    final value = double.tryParse(_discountCtrl.text) ?? 0;
    if (_discountType == DiscountType.percentage) {
      return _subtotal * value / 100;
    }
    return value;
  }

  double get _taxableAmount => _subtotal - _discountAmount;

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

  double get _grandTotal => _taxableAmount + _taxAmount;

  String get _currencySymbol => CurrencyFormatter.getCurrencySymbol(_currency);

  Future<void> _selectDate(bool isDueDate) async {
    final initial = isDueDate ? (_dueDate ?? DateTime.now().add(const Duration(days: 30))) : _invoiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
          _dueDatePreset = 'Custom';
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  void _setDueDatePreset(String preset) {
    setState(() {
      _dueDatePreset = preset;
      switch (preset) {
        case 'Net 15':
          _dueDate = _invoiceDate.add(const Duration(days: 15));
          break;
        case 'Net 30':
          _dueDate = _invoiceDate.add(const Duration(days: 30));
          break;
        case 'Net 60':
          _dueDate = _invoiceDate.add(const Duration(days: 60));
          break;
        case 'Due on Receipt':
          _dueDate = _invoiceDate;
          break;
      }
    });
  }

  Future<void> _selectClient() async {
    final client = await Navigator.push<ClientModel>(
      context,
      MaterialPageRoute(builder: (_) => const ClientListScreen(selectionMode: true)),
    );
    if (client != null) {
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

  void _addLineItem() {
    setState(() => _lineItems.add(_LineItemEntry.empty()));
  }

  void _removeLineItem(int index) {
    setState(() => _lineItems.removeAt(index));
  }

  Future<void> _showAddItemSheet({int? editIndex}) async {
    final entry = editIndex != null ? _lineItems[editIndex] : _LineItemEntry.empty();
    final descCtrl = TextEditingController(text: entry.descCtrl.text);
    final qtyCtrl = TextEditingController(text: entry.qtyCtrl.text == '0' ? '' : entry.qtyCtrl.text);
    final priceCtrl = TextEditingController(text: entry.priceCtrl.text == '0' ? '' : entry.priceCtrl.text);
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final qty = double.tryParse(qtyCtrl.text) ?? 0;
          final price = double.tryParse(priceCtrl.text) ?? 0;
          final total = qty * price;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Form(
              key: formKey,
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
                  const SizedBox(height: 20),
                  Text(
                    editIndex != null ? 'Edit Item' : 'Add Line Item',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Item / Service Description *',
                    hint: 'e.g. Web Design Services',
                    controller: descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity *',
                          hint: '1',
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          onChanged: (_) => setModalState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if ((double.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Unit Price *',
                          hint: '0.00',
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                          prefixText: '$_currencySymbol ',
                          onChanged: (_) => setModalState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if ((double.tryParse(v) ?? 0) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Line Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                          CurrencyFormatter.format(total, currencySymbol: _currencySymbol),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: editIndex != null ? 'Update Item' : 'Add Item',
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == true) {
      final newEntry = _LineItemEntry(
        id: entry.id,
        descCtrl: TextEditingController(text: descCtrl.text.trim()),
        qtyCtrl: TextEditingController(text: qtyCtrl.text),
        priceCtrl: TextEditingController(text: priceCtrl.text),
      );

      setState(() {
        if (editIndex != null) {
          _lineItems[editIndex] = newEntry;
        } else {
          _lineItems.add(newEntry);
        }
      });
    }
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final isPro = context.read<BillingService>().isPro;
      final prefs = await SharedPreferences.getInstance();

      final profile = BusinessProfile(
        businessName: prefs.getString('biz_name') ?? 'My Business',
        address: prefs.getString('biz_address'),
        phone: prefs.getString('biz_phone'),
        email: prefs.getString('biz_email'),
        gstin: prefs.getString('biz_gstin'),
        bankName: prefs.getString('biz_bank_name'),
        accountNumber: prefs.getString('biz_account'),
        ifscCode: prefs.getString('biz_ifsc'),
        logoPath: prefs.getString('biz_logo_path'),
        currency: _currency,
      );

      // Build invoice model
      final now = DateTime.now();
      final invoiceId = widget.existingInvoice?.id ?? const Uuid().v4();

      final lineItems = _lineItems.asMap().entries.map((e) {
        final item = e.value;
        final qty = double.tryParse(item.qtyCtrl.text) ?? 1;
        final price = double.tryParse(item.priceCtrl.text) ?? 0;
        return LineItemModel(
          id: item.id,
          invoiceId: invoiceId,
          description: item.descCtrl.text.trim(),
          quantity: qty,
          unitPrice: price,
          total: qty * price,
          sortOrder: e.key,
        );
      }).toList();

      final invoice = InvoiceModel(
        id: invoiceId,
        invoiceNumber: _invoiceNumberCtrl.text.trim(),
        clientId: _selectedClient?.id,
        clientName: _clientNameCtrl.text.trim(),
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
        status: widget.existingInvoice?.status ?? InvoiceStatus.unpaid,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        currency: _currency,
        createdAt: widget.existingInvoice?.createdAt ?? now,
        updatedAt: now,
        lineItems: lineItems,
      );

      // Save to DB
      await DbProvider.insert(DbProvider.tableInvoices, invoice.toMap());
      // Delete old line items and re-insert
      await DbProvider.delete(DbProvider.tableLineItems, 'invoice_id = ?', [invoiceId]);
      for (final item in lineItems) {
        await DbProvider.insert(DbProvider.tableLineItems, item.toMap());
      }

      // Generate PDF
      final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
        invoice: invoice,
        businessProfile: profile,
        isPro: isPro,
      );

      setState(() => _isGenerating = false);

      if (!mounted) return;

      // Show interstitial ad for free users
      if (!isPro) {
        AdManager.showInterstitialAd(onAdDismissed: () {
          if (mounted) _showPdfPreview(pdfBytes, invoice);
        });
      } else {
        _showPdfPreview(pdfBytes, invoice);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showPdfPreview(Uint8List pdfBytes, InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Text(
                    'Invoice Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await PdfGeneratorService.saveAndGetPath(
                          pdfBytes,
                          invoice.invoiceNumber,
                        );
                        await Share.shareXFiles(
                          [XFile(path)],
                          text: 'Invoice ${invoice.invoiceNumber}',
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              children: [
                // ── Card 1: Invoice Details ──────────────────────────────
                _buildCard(
                  title: 'Invoice Details',
                  icon: Icons.receipt_outlined,
                  children: [
                    CustomTextField(
                      label: 'Invoice Number',
                      controller: _invoiceNumberCtrl,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Invoice Date',
                            date: _invoiceDate,
                            onTap: () => _selectDate(false),
                            dateFormat: dateFormat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Due Date',
                            date: _dueDate,
                            onTap: () => _selectDate(true),
                            dateFormat: dateFormat,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Due date presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Net 15', 'Net 30', 'Net 60', 'Due on Receipt'].map((preset) {
                          final isSelected = _dueDatePreset == preset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _setDueDatePreset(preset),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.slate50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Card 2: Billed To ────────────────────────────────────
                _buildCard(
                  title: 'Billed To',
                  icon: Icons.person_outline,
                  action: TextButton.icon(
                    onPressed: _selectClient,
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: const Text('Select Client'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  children: [
                    CustomTextField(
                      label: 'Client Name *',
                      hint: 'John Doe / Acme Corp',
                      controller: _clientNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Email',
                            hint: 'client@example.com',
                            controller: _clientEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Phone',
                            hint: '+91 98765 43210',
                            controller: _clientPhoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Address',
                      hint: '123 Main St, City',
                      controller: _clientAddressCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'GSTIN',
                      hint: '22AAAAA0000A1Z5',
                      controller: _clientGstinCtrl,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Card 3: Line Items ───────────────────────────────────
                _buildCard(
                  title: 'Line Items',
                  icon: Icons.list_alt_outlined,
                  children: [
                    if (_lineItems.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No items added yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else ...[
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: const [
                            Expanded(flex: 4, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                            Expanded(flex: 2, child: Text('Qty × Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                            SizedBox(width: 32),
                          ],
                        ),
                      ),
                      ...List.generate(_lineItems.length, (index) {
                        final item = _lineItems[index];
                        return _buildLineItemRow(item, index);
                      }),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showAddItemSheet(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Card 4: Financials ───────────────────────────────────
                _buildCard(
                  title: 'Financials',
                  icon: Icons.calculate_outlined,
                  children: [
                    // Subtotal
                    _buildFinancialRow(
                      'Subtotal',
                      CurrencyFormatter.format(_subtotal, currencySymbol: _currencySymbol),
                      isBold: false,
                    ),
                    const Divider(height: 20),

                    // Discount toggle
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Add Discount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (v) => setState(() => _hasDiscount = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasDiscount) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Type selector
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDiscountTypeBtn('%', DiscountType.percentage),
                                _buildDiscountTypeBtn('Flat', DiscountType.flat),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              hint: _discountType == DiscountType.percentage ? '10' : '500',
                              controller: _discountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              onChanged: (_) => setState(() {}),
                              prefixText: _discountType == DiscountType.flat ? '$_currencySymbol ' : null,
                              suffixText: _discountType == DiscountType.percentage ? '%' : null,
                            ),
                          ),
                        ],
                      ),
                      if (_discountAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildFinancialRow(
                            'Discount',
                            '-${CurrencyFormatter.format(_discountAmount, currencySymbol: _currencySymbol)}',
                            valueColor: AppColors.statusPaid,
                          ),
                        ),
                    ],
                    const Divider(height: 20),

                    // Tax toggle
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Add GST / Tax', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: _hasTax,
                          onChanged: (v) => setState(() => _hasTax = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasTax) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('IGST', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Switch(
                            value: _useIGST,
                            onChanged: (v) => setState(() => _useIGST = v),
                            activeColor: AppColors.primary,
                          ),
                          const Text('SGST + CGST', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_useIGST)
                        CustomTextField(
                          label: 'IGST Rate (%)',
                          hint: '18',
                          controller: _igstCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                          onChanged: (_) => setState(() {}),
                          suffixText: '%',
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'SGST (%)',
                                hint: '9',
                                controller: _sgstCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                                suffixText: '%',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'CGST (%)',
                                hint: '9',
                                controller: _cgstCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                                suffixText: '%',
                              ),
                            ),
                          ],
                        ),
                      if (_taxAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildFinancialRow(
                            _useIGST
                                ? 'IGST (${_igstCtrl.text}%)'
                                : 'Tax (SGST ${_sgstCtrl.text}% + CGST ${_cgstCtrl.text}%)',
                            CurrencyFormatter.format(_taxAmount, currencySymbol: _currencySymbol),
                          ),
                        ),
                    ],
                    const Divider(height: 20),

                    // Notes
                    CustomTextField(
                      label: 'Notes / Terms (optional)',
                      hint: 'Payment due within 30 days...',
                      controller: _notesCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),

            // ── Sticky Bottom Bar ────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.format(_grandTotal, currencySymbol: _currencySymbol),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Generate PDF',
                        isLoading: _isGenerating,
                        onPressed: _generatePdf,
                        icon: Icons.picture_as_pdf_outlined,
                        height: 52,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? action,
  }) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (action != null) ...[
                const Spacer(),
                action,
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    date != null ? dateFormat.format(date) : 'Select',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemRow(_LineItemEntry item, int index) {
    final qty = double.tryParse(item.qtyCtrl.text) ?? 0;
    final price = double.tryParse(item.priceCtrl.text) ?? 0;
    final total = qty * price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.descCtrl.text.isEmpty ? 'Unnamed item' : item.descCtrl.text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${qty % 1 == 0 ? qty.toInt() : qty} × $_currencySymbol${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.format(total, currencySymbol: _currencySymbol),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 32,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
              onSelected: (value) {
                if (value == 'edit') _showAddItemSheet(editIndex: index);
                if (value == 'delete') _removeLineItem(index);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.accentRed)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountTypeBtn(String label, DiscountType type) {
    final isSelected = _discountType == type;
    return GestureDetector(
      onTap: () => setState(() => _discountType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LineItemEntry {
  final String id;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _LineItemEntry({
    required this.id,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
  });

  factory _LineItemEntry.empty() => _LineItemEntry(
        id: const Uuid().v4(),
        descCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        priceCtrl: TextEditingController(text: '0'),
      );

  double get total {
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}
