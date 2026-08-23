import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../models/saved_item_model.dart';
import '../services/item_service.dart';

/// A rich bottom-sheet form for creating or editing a SavedItemModel.
///
/// Returns the saved [SavedItemModel] on success, or null if dismissed.
class CreateEditItemSheet extends StatefulWidget {
  final SavedItemModel? existingItem;

  const CreateEditItemSheet({super.key, this.existingItem});

  /// Convenience launcher — opens the sheet and returns the saved item (or null).
  static Future<SavedItemModel?> show(
    BuildContext context, {
    SavedItemModel? existingItem,
  }) {
    return showModalBottomSheet<SavedItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CreateEditItemSheet(existingItem: existingItem),
    );
  }

  @override
  State<CreateEditItemSheet> createState() => _CreateEditItemSheetState();
}

class _CreateEditItemSheetState extends State<CreateEditItemSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _discountRateCtrl;
  late final TextEditingController _taxRateCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _categoryCtrl;

  String _selectedUnit = 'pcs';
  bool _isTaxable = true;
  bool _isSaving = false;

  List<String> _existingCategories = [];

  static const List<String> _unitOptions = [
    'pcs',
    'hrs',
    'days',
    'kg',
    'g',
    'ltr',
    'ml',
    'ft',
    'm',
    'sqft',
    'sqm',
    'box',
    'unit',
    'lot',
  ];

  static const Map<String, String> _unitLabels = {
    'pcs': 'Pieces',
    'hrs': 'Hours',
    'days': 'Days',
    'kg': 'Kilograms',
    'g': 'Grams',
    'ltr': 'Litres',
    'ml': 'Millilitres',
    'ft': 'Feet',
    'm': 'Metres',
    'sqft': 'Sq. Feet',
    'sqm': 'Sq. Metres',
    'box': 'Boxes',
    'unit': 'Units',
    'lot': 'Lots',
  };

  static const List<double> _quickTaxRates = [0, 5, 12, 18, 28];
  static const List<double> _quickDiscountRates = [0, 5, 10, 15, 20, 25];

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? item.unitPrice.toString().replaceAll('.0', '') : '',
    );
    _qtyCtrl = TextEditingController(
      text: item != null
          ? item.defaultQuantity.toString().replaceAll('.0', '')
          : '1',
    );
    _discountRateCtrl = TextEditingController(
      text: item != null && item.discountRate > 0
          ? item.discountRate.toString().replaceAll('.0', '')
          : '',
    );
    _taxRateCtrl = TextEditingController(
      text: item != null && item.taxRate > 0
          ? item.taxRate.toString().replaceAll('.0', '')
          : '',
    );
    _hsnCtrl = TextEditingController(text: item?.hsnCode ?? '');
    _categoryCtrl = TextEditingController(text: item?.category ?? '');
    _selectedUnit = item?.unit ?? 'pcs';
    _isTaxable = item?.isTaxable ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ItemService.getCategories();
    if (mounted) setState(() => _existingCategories = cats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _discountRateCtrl.dispose();
    _taxRateCtrl.dispose();
    _hsnCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final item = SavedItemModel(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      unit: _selectedUnit,
      hsnCode:
          _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
      category:
          _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      isTaxable: _isTaxable,
      taxRate: _isTaxable ? (double.tryParse(_taxRateCtrl.text) ?? 0) : 0,
      discountRate: double.tryParse(_discountRateCtrl.text) ?? 0,
      defaultQuantity: double.tryParse(_qtyCtrl.text) ?? 1,
      createdAt: widget.existingItem?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      await ItemService.updateItem(item);
    } else {
      await ItemService.createItem(item);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencySymbol = currencyProvider.currencySymbol;
    final currencyCode = currencyProvider.selectedCurrency.code;

    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final qty = double.tryParse(_qtyCtrl.text) ?? 1;
    final discountPercent = double.tryParse(_discountRateCtrl.text) ?? 0;
    final taxPercent = _isTaxable ? (double.tryParse(_taxRateCtrl.text) ?? 0) : 0;

    final baseSubtotal = price * qty;
    final discountAmount = ((baseSubtotal * discountPercent / 100).clamp(0.0, baseSubtotal)).toDouble();
    final taxableBase = ((baseSubtotal - discountAmount).clamp(0.0, double.infinity)).toDouble();
    final taxAmount = _isTaxable ? (taxableBase * taxPercent / 100) : 0.0;
    final netTotal = taxableBase + taxAmount;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Item' : 'New Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.slate400,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Name (required)
              CustomTextField(
                label: 'Item Name *',
                hint: 'e.g. Web Design, Consulting, T-Shirt',
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Item name is required';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Description (optional)
              CustomTextField(
                label: 'Description',
                hint: 'Optional details about this item or service',
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 14),

              // Price + Default Qty
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Unit Price *',
                      hint: '0.00',
                      controller: _priceCtrl,
                      prefixText: '$currencySymbol ',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Default Qty',
                      hint: '1',
                      controller: _qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Unit of Measurement dropdown
              _buildSectionLabel('Unit of Measurement'),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.slate500),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: _unitOptions.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(
                          '${_unitLabels[u] ?? u} ($u)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quick Unit Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['pcs', 'hrs', 'days', 'kg', 'box', 'unit', 'sqft'].map((u) {
                    final isSel = _selectedUnit == u;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedUnit = u);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.slate100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            u,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.slate700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Category with autocomplete
              _buildSectionLabel('Category'),
              const SizedBox(height: 6),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _categoryCtrl.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _existingCategories;
                  }
                  return _existingCategories.where(
                    (c) => c
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()),
                  );
                },
                onSelected: (String selection) {
                  _categoryCtrl.text = selection;
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                  textController.addListener(() {
                    _categoryCtrl.text = textController.text;
                  });
                  if (textController.text != _categoryCtrl.text) {
                    textController.text = _categoryCtrl.text;
                  }
                  return CustomTextField(
                    hint: 'e.g. Design, Development, Products',
                    controller: textController,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
              ),
              const SizedBox(height: 14),

              // HSN / SAC code
              CustomTextField(
                label: 'HSN / SAC Code',
                hint: 'e.g. 998311',
                controller: _hsnCtrl,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // ─── Individual Item Discount Section ───
              _buildCardSection(
                title: 'Item Discount',
                subtitle: 'Set a default percentage discount for this item',
                icon: Icons.local_offer_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Discount Percentage (%)',
                      hint: '0',
                      controller: _discountRateCtrl,
                      suffixText: '%',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickDiscountRates.map((rate) {
                          final label = rate == 0 ? 'None (0%)' : '${rate.toInt()}%';
                          final isSelected = (double.tryParse(_discountRateCtrl.text) ?? 0) == rate;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _discountRateCtrl.text = rate == 0 ? '' : rate.toString().replaceAll('.0', '');
                                });
                              },
                              selectedColor: const Color(0xFFFEF3C7),
                              backgroundColor: AppColors.slate100,
                              labelStyle: TextStyle(color: isSelected ? const Color(0xFFB45309) : AppColors.slate700),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── Individual Item Tax Section ───
              _buildCardSection(
                title: 'Tax Configuration',
                subtitle: 'Specify whether tax applies and the item tax rate',
                icon: Icons.receipt_long_rounded,
                iconBg: _isTaxable ? AppColors.squircleGreen : AppColors.slate100,
                iconColor: _isTaxable ? AppColors.squircleGreenIcon : AppColors.slate400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Apply Tax to this Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Switch.adaptive(
                          value: _isTaxable,
                          onChanged: (val) => setState(() => _isTaxable = val),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_isTaxable) ...[
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Tax Rate (%)',
                        hint: 'e.g. 18',
                        controller: _taxRateCtrl,
                        suffixText: '%',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickTaxRates.map((rate) {
                            final label = rate == 0 ? '0% (Exempt)' : '${rate.toInt()}%';
                            final isSelected = (double.tryParse(_taxRateCtrl.text) ?? 0) == rate;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _taxRateCtrl.text = rate == 0 ? '0' : rate.toString().replaceAll('.0', '');
                                  });
                                },
                                selectedColor: AppColors.squircleGreen,
                                backgroundColor: AppColors.slate100,
                                labelStyle: TextStyle(color: isSelected ? AppColors.squircleGreenIcon : AppColors.slate700),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Live Price Breakdown Calculator Preview ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calculate_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Estimated Item Total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base (${qty.toString().replaceAll(".0", "")} × ${CurrencyFormatter.format(price, currencyCode: currencyCode)})',
                          style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                        ),
                        Text(
                          CurrencyFormatter.format(baseSubtotal, currencyCode: currencyCode),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Item Discount (${discountPercent.toString().replaceAll(".0", "")}%)',
                            style: const TextStyle(fontSize: 13, color: Color(0xFFD97706)),
                          ),
                          Text(
                            '-${CurrencyFormatter.format(discountAmount, currencyCode: currencyCode)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ],
                    if (_isTaxable && taxAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax (${taxPercent.toString().replaceAll(".0", "")}%)',
                            style: const TextStyle(fontSize: 13, color: AppColors.squircleGreenIcon),
                          ),
                          Text(
                            '+${CurrencyFormatter.format(taxAmount, currencyCode: currencyCode)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.squircleGreenIcon),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16, color: AppColors.cardBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Item Total:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          CurrencyFormatter.format(netTotal, currencyCode: currencyCode),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Item' : 'Save Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.slate500,
      ),
    );
  }
}
