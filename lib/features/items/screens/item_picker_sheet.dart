import 'package:flutter/material.dart';
import '../../../core/utils/number_text.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../invoices/models/line_item_model.dart';
import '../models/saved_item_model.dart';
import '../services/item_service.dart';
import 'create_edit_item_sheet.dart';

/// A picker sheet that lets users select saved items from their catalog
/// and converts them to [LineItemModel]s for invoices/estimates.
///
/// Supports multi-select mode and search.
class ItemPickerSheet extends StatefulWidget {
  /// The invoice/estimate ID to attach line items to.
  final String invoiceId;

  /// The document's currency, used to show prices. Defaults to the app's.
  final String? currencyCode;

  const ItemPickerSheet({super.key, required this.invoiceId, this.currencyCode});

  /// Opens the picker and returns selected line items, or null if dismissed.
  static Future<List<LineItemModel>?> show(
    BuildContext context, {
    required String invoiceId,
    String? currencyCode,
  }) {
    return showModalBottomSheet<List<LineItemModel>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ItemPickerSheet(invoiceId: invoiceId, currencyCode: currencyCode),
    );
  }

  @override
  State<ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<ItemPickerSheet> {
  List<SavedItemModel> _allItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await ItemService.getAllItems(orderBy: 'name COLLATE NOCASE ASC');
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    }
  }

  List<SavedItemModel> get _filteredItems {
    if (_searchQuery.isEmpty) return _allItems;
    final q = _searchQuery.toLowerCase();
    return _allItems.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.description?.toLowerCase().contains(q) ?? false) ||
          (item.category?.toLowerCase().contains(q) ?? false) ||
          (item.hsnCode?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// A saved item as an invoice line, keeping its own price, discount, tax
  /// rate, HSN/SAC code and unit. A non-taxable item is exempt (rate 0); a
  /// taxable item with no rate of its own uses the document's rate.
  LineItemModel _toLineItem(SavedItemModel item) {
    final double? taxRate = !item.isTaxable ? 0 : (item.taxRate > 0 ? item.taxRate : null);
    return LineItemModel.create(
      id: const Uuid().v4(),
      invoiceId: widget.invoiceId,
      description: item.name,
      quantity: item.defaultQuantity > 0 ? item.defaultQuantity : 1,
      unitPrice: item.unitPrice,
      discountRate: item.discountRate,
      taxRate: taxRate,
      hsnSac: (item.hsnCode?.trim().isEmpty ?? true) ? null : item.hsnCode!.trim(),
      unit: item.unit.trim().isEmpty ? null : item.unit.trim(),
    );
  }

  void _confirmSelection() {
    // In the order the items were tapped.
    final byId = {for (final item in _allItems) item.id: item};
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] != null) _toLineItem(byId[id]!),
    ];
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    // Prices show in the document's currency, not the app default.
    final currencyCode = widget.currencyCode ?? currencyProvider.selectedCurrency.code;
    final filtered = _filteredItems;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick from Catalog',
                      style: AppTypography.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      Text(
                        '${_selectedIds.length} selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    // Create new item shortcut
                    TextButton.icon(
                      onPressed: () async {
                        final newItem =
                            await CreateEditItemSheet.show(context);
                        if (newItem != null) {
                          await _loadItems();
                          if (mounted) {
                            setState(() => _selectedIds.add(newItem.id));
                          }
                        }
                      },
                      icon:
                          const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'New',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.slate400,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.slate400),
                  hintStyle:
                      TextStyle(color: AppColors.slate400, fontSize: 14),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim()),
              ),
            ),
          ),

          // Items list
          Flexible(
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                : filtered.isEmpty
                    ? _buildPickerEmpty()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected =
                              _selectedIds.contains(item.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryMuted
                                  : AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(item.id);
                                    } else {
                                      _selectedIds.add(item.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Checkbox indicator
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.slate300,
                                            width: isSelected ? 0 : 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: AppColors.onPrimary,
                                                size: 18,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),

                                      // Item info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  CurrencyFormatter.format(
                                                    item.unitPrice,
                                                    currencyCode:
                                                        currencyCode,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: item.discountRate > 0
                                                        ? AppColors.slate400
                                                        : AppColors.slate600,
                                                    decoration: item.discountRate > 0
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                if (item.discountRate > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    CurrencyFormatter.format(
                                                      item.discountedUnitPrice,
                                                      currencyCode: currencyCode,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.statusPartiallyPaid,
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  ' × ${NumberText.trim(item.defaultQuantity)} ${item.unit}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.slate500,
                                                  ),
                                                ),
                                                if (item.discountRate > 0) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.statusPartiallyPaidBg,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '-${NumberText.trim(item.discountRate)}%',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.statusPartiallyPaid,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (item.isTaxable && item.taxRate > 0) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.squircleGreen,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '+${NumberText.trim(item.taxRate)}% Tax',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.squircleGreenIcon,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Total preview
                                      Text(
                                        CurrencyFormatter.format(
                                          item.discountedUnitPrice *
                                              item.defaultQuantity,
                                          currencyCode: currencyCode,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom action bar
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Add ${_selectedIds.length} Item${_selectedIds.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickerEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: AppColors.slate400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No items match "$_searchQuery"'
                  : 'No saved items yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create items in your catalog to quickly add them here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                final newItem = await CreateEditItemSheet.show(context);
                if (newItem != null) {
                  await _loadItems();
                  if (mounted) {
                    setState(() => _selectedIds.add(newItem.id));
                  }
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create New Item'),
            ),
          ],
        ),
      ),
    );
  }
}
