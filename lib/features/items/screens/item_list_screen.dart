import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/app_popup_menu.dart';
import '../models/saved_item_model.dart';
import '../services/item_service.dart';
import 'create_edit_item_sheet.dart';

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
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

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

  /// Public entry-point so the nav shell can trigger a refresh via GlobalKey.
  void reload() => _loadItems();

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    final items = await ItemService.getAllItems(orderBy: 'name ASC');
    final cats = await ItemService.getCategories();

    if (mounted) {
      setState(() {
        _items = items;
        _categories = cats;
        _isLoading = false;
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

  // Group items alphabetically by first letter
  Map<String, List<SavedItemModel>> _groupAlphabetically(
      List<SavedItemModel> list) {
    final Map<String, List<SavedItemModel>> grouped = {};
    for (final item in list) {
      final key = item.name.isNotEmpty
          ? item.name[0].toUpperCase()
          : '#';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
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
      id: '${now.millisecondsSinceEpoch}',
      name: '${item.name} (Copy)',
      description: item.description,
      unitPrice: item.unitPrice,
      unit: item.unit,
      hsnCode: item.hsnCode,
      category: item.category,
      isTaxable: item.isTaxable,
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
    final grouped = _groupAlphabetically(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search items, categories, HSN...',
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: AppColors.slate400, fontSize: 15),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchCtrl.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _createItem();
                },
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Category filter chips
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        ..._categories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(cat, cat),
                          ),
                        ),
                        _buildFilterChip('Uncategorized', 'uncategorized'),
                      ],
                    ),
                  ),
                ),
              ),

            // Summary strip
            if (!_isLoading && _items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} item${filtered.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                      if (_filterCategory != 'all' ||
                          _searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(filtered)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final groupKey = grouped.keys.elementAt(index);
                      final itemsInGroup = grouped[groupKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Header
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 14,
                              bottom: 8,
                              left: 4,
                            ),
                            child: Text(
                              groupKey,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                          ...itemsInGroup.asMap().entries.map(
                                (entry) => StaggeredEntrance(
                                  index: entry.key,
                                  child: _buildItemCard(entry.value),
                                ),
                              ),
                        ],
                      );
                    },
                    childCount: grouped.keys.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _createItem();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Item',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterCategory == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _filterCategory = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No items found for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try a different search term',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _isSearching = false;
                  });
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      );
    }

    return EmptyStateView(
      icon: Icons.inventory_2_rounded,
      title: 'No Items Yet',
      subtitle: _filterCategory == 'all'
          ? 'Save your products & services here to quickly add them to invoices'
          : 'No items in this category',
      isDarkBackground: false,
      actionLabel: 'Add Your First Item',
      onAction: _createItem,
    );
  }

  Widget _buildItemCard(SavedItemModel item) {
    final currencyProvider = context.read<CurrencyProvider>();
    final currencyCode = currencyProvider.selectedCurrency.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editItem(item),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon tile
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.isTaxable
                        ? AppColors.squircleGreen
                        : AppColors.squircleBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isTaxable
                        ? Icons.sell_rounded
                        : Icons.sell_outlined,
                    color: item.isTaxable
                        ? AppColors.squircleGreenIcon
                        : AppColors.squircleBlueIcon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              item.unitPrice,
                              currencyCode: currencyCode,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            ' / ${item.unit}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                          if (item.hsnCode != null &&
                              item.hsnCode!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'HSN: ${item.hsnCode}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.category != null &&
                              item.category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.squirclePurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.squirclePurpleIcon,
                                ),
                              ),
                            ),
                          if (item.discountRate > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer_rounded,
                                    size: 10,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.discountRate.toString().replaceAll('.0', '')}% OFF',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.isTaxable && item.taxRate > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.squircleGreen,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'Tax ${item.taxRate.toString().replaceAll('.0', '')}%',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.squircleGreenIcon,
                                ),
                              ),
                            )
                          else if (!item.isTaxable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Tax Exempt',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Popup menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.slate500,
                    size: 20,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        _editItem(item);
                        break;
                      case 'duplicate':
                        _duplicateItemDirect(item);
                        break;
                      case 'delete':
                        _deleteItem(item);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    AppPopupMenuItem.item(
                      value: 'edit',
                      title: 'Edit Item',
                      icon: Icons.edit_outlined,
                    ),
                    AppPopupMenuItem.item(
                      value: 'duplicate',
                      title: 'Duplicate',
                      icon: Icons.copy_rounded,
                    ),
                    AppPopupMenuItem.divider(),
                    AppPopupMenuItem.item(
                      value: 'delete',
                      title: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
