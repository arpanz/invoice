import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/number_text.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/paper.dart';
import '../../../shared_widgets/tab_chrome.dart';
import '../../../core/theme/app_typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saved_item_model.dart';
import '../services/item_service.dart';
import 'create_edit_item_sheet.dart';
import '../../../core/theme/app_icons.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => ItemListScreenState();
}

class ItemListScreenState extends State<ItemListScreen> {
  List<SavedItemModel> _items = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _filterCategory = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadItems();

  /// Called by the shell's search bar.
  void setSearch(String query) {
    final q = query.trim();
    if (q == _searchQuery) return;
    setState(() => _searchQuery = q);
  }

  /// For the shell's create sheet.
  Future<void> createNew() => _createItem();

  // Only the first load shows a spinner; reloads swap the list in place.
  Future<void> _loadItems() async {

    final items = await ItemService.getAllItems(orderBy: 'name COLLATE NOCASE ASC');
    final cats = await ItemService.getCategories();

    if (mounted) {
      setState(() {
        _items = items;
        _categories = cats;
        _isLoading = false;
        // The filtered category may no longer exist (renamed or its last
        // item deleted): fall back to all items rather than an empty list.
        final stillThere = switch (_filterCategory) {
          'all' => true,
          'uncategorized' => items.any((i) => (i.category ?? '').isEmpty),
          final c => cats.contains(c),
        };
        if (!stillThere) _filterCategory = 'all';
      });
    }
  }

  List<SavedItemModel> get _filteredItems {
    return _items.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchDesc =
            item.description?.toLowerCase().contains(q) ?? false;
        final matchHsn = item.hsnCode?.toLowerCase().contains(q) ?? false;
        final matchCat = item.category?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchDesc && !matchHsn && !matchCat) return false;
      }

      // Category filter
      if (_filterCategory != 'all') {
        if (_filterCategory == 'uncategorized') {
          if (item.category != null && item.category!.isNotEmpty) return false;
        } else {
          if (item.category != _filterCategory) return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _createItem() async {
    final result = await CreateEditItemSheet.show(context);
    if (result != null) await _loadItems();
  }

  Future<void> _editItem(SavedItemModel item) async {
    final result =
        await CreateEditItemSheet.show(context, existingItem: item);
    if (result != null) await _loadItems();
  }



  Future<void> _duplicateItemDirect(SavedItemModel item) async {
    final now = DateTime.now();
    final copy = SavedItemModel(
      id: const Uuid().v4(),
      name: '${item.name} (Copy)',
      description: item.description,
      unitPrice: item.unitPrice,
      unit: item.unit,
      hsnCode: item.hsnCode,
      category: item.category,
      isTaxable: item.isTaxable,
      taxRate: item.taxRate,
      discountRate: item.discountRate,
      defaultQuantity: item.defaultQuantity,
      createdAt: now,
      updatedAt: now,
    );
    await ItemService.createItem(copy);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${item.name}"'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    await _loadItems();
  }

  Future<void> _deleteItem(SavedItemModel item) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Item?',
      message:
          'Delete "${item.name}"? This won\'t affect existing invoices.',
    );
    if (confirm == true) {
      await ItemService.deleteItem(item.id);
      await _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final rows = <Object>[];
    String? letter;
    for (final item in filtered) {
      final l = item.name.trim().isEmpty ? '#' : item.name.trim()[0].toUpperCase();
      if (l != letter) {
        rows.add(l);
        letter = l;
      }
      rows.add(item);
    }
    final hasUncategorized = _items.any((i) => (i.category ?? '').isEmpty);

    Widget pill(String label, String value) => FilterPill(
      label: label,
      selected: _filterCategory == value,
      onTap: () => setState(() => _filterCategory = value),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadItems,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: TabHeader(
                  title: 'Items',
                  caption: _items.isEmpty
                      ? 'Products & services'
                      : '${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
                ),
              ),
              if (_categories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedBarDelegate(
                    child: FilterRow(
                      children: [
                        pill('All', 'all'),
                        ..._categories.map((cat) => pill(cat, cat)),
                        if (hasUncategorized) pill('Uncategorized', 'uncategorized'),
                      ],
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(padding: const EdgeInsets.only(bottom: 100), child: _buildEmptyState()),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      if (row is String) return ListSectionLabel(row);
                      return _buildItemCard(row as SavedItemModel);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: ListFootnote('Tap to edit · hold for more')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return EmptyStateView(
        icon: AppIcons.searchOff,
        title: 'No Results',
        subtitle: 'No items match "$_searchQuery"',
        isDarkBackground: false,
      );
    }
    return EmptyStateView(
      icon: AppIcons.items,
      title: 'No Items Yet',
      subtitle: _filterCategory == 'all'
          ? 'Save your products & services here to quickly add them to invoices'
          : 'No items in this category',
      isDarkBackground: false,
      actionLabel: 'Add Your First Item',
      onAction: _createItem,
    );
  }

  void _showItemActions(SavedItemModel item) {
    Haptics.confirm();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        Widget action(IconData icon, String label, VoidCallback f, {Color? color}) {
          final c = color ?? AppColors.ink;
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(icon, color: c, size: 20),
            title: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: c)),
            onTap: () {
              Navigator.pop(ctx);
              f();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(item.name, style: AppTypography.serif(fontSize: 20, color: AppColors.ink)),
                ),
                action(AppIcons.edit, 'Edit item', () => _editItem(item)),
                action(AppIcons.copy, 'Duplicate', () => _duplicateItemDirect(item)),
                Divider(color: AppColors.hairline, height: 12),
                action(AppIcons.delete, 'Delete item', () => _deleteItem(item), color: AppColors.error),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(SavedItemModel item) {
    final currencyCode = context.read<CurrencyProvider>().selectedCurrency.code;
    final meta = <String>[
      if ((item.category ?? '').isNotEmpty) item.category!,
      if ((item.hsnCode ?? '').isNotEmpty) 'HSN ${item.hsnCode}',
      if (item.isTaxable && item.taxRate > 0) 'Tax ${NumberText.trim(item.taxRate)}%',
      if (!item.isTaxable) 'Tax exempt',
      if (item.discountRate > 0) '${NumberText.trim(item.discountRate)}% off',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PaperSlip(
        onTap: () {
          Haptics.tap();
          _editItem(item);
        },
        onLongPress: () => _showItemActions(item),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(item.unitPrice, currencyCode: currencyCode),
                  style: AppTypography.money(fontSize: 17, color: AppColors.ink, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text('per ${item.unit}', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
