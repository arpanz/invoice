import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/models/pdf_theme.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';
import '../../paywall/paywall_screen.dart';
import '../models/estimate_model.dart';
import 'create_estimate_screen.dart';
import 'estimate_preview_screen.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/app_popup_menu.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => EstimateListScreenState();
}

class EstimateListScreenState extends State<EstimateListScreen> {
  List<EstimateModel> _allEstimates = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'declined', 'converted'
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  double _totalEstimated = 0.0;
  double _totalAccepted = 0.0;
  double _totalPending = 0.0;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Public entry-point so the navigation shell can trigger a refresh via GlobalKey.
  void reload() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

    final rows = await DbProvider.query(
      DbProvider.tableEstimates,
      orderBy: 'estimate_date DESC',
    );

    final List<EstimateModel> loaded = [];
    double estimatedSum = 0.0;
    double acceptedSum = 0.0;
    double pendingSum = 0.0;

    for (final row in rows) {
      final estimateId = row['id'] as String;
      final itemRows = await DbProvider.query(
        DbProvider.tableEstimateLineItems,
        where: 'estimate_id = ?',
        whereArgs: [estimateId],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      final est = EstimateModel.fromMap(row, items: items);
      loaded.add(est);

      estimatedSum += est.grandTotal;
      if (est.status == EstimateStatus.accepted || est.status == EstimateStatus.converted) {
        acceptedSum += est.grandTotal;
      } else if (est.status == EstimateStatus.pending) {
        pendingSum += est.grandTotal;
      }
    }

    if (mounted) {
      setState(() {
        _allEstimates = loaded;
        _totalEstimated = estimatedSum;
        _totalAccepted = acceptedSum;
        _totalPending = pendingSum;
        _isLoading = false;
      });
    }
  }

  List<EstimateModel> get _filteredEstimates {
    return _allEstimates.where((est) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = est.estimateNumber.toLowerCase().contains(q);
        final matchesClient = est.clientName.toLowerCase().contains(q);
        if (!matchesNum && !matchesClient) return false;
      }

      // Status chip filter
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'pending') return est.status == EstimateStatus.pending;
      if (_selectedFilter == 'accepted') return est.status == EstimateStatus.accepted;
      if (_selectedFilter == 'declined') return est.status == EstimateStatus.declined;
      if (_selectedFilter == 'converted') return est.status == EstimateStatus.converted;
      return true;
    }).toList();
  }

  Future<void> _openEstimatePreview(EstimateModel estimate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimatePreviewScreen(estimate: estimate),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _createNewEstimate() async {
    HapticFeedback.mediumImpact();
    if (await CreateEstimateScreen.canCreateNewEstimate(context)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateEstimateScreen()),
      );
      if (mounted) {
        await _loadData();
      }
    }
  }

  Future<void> _quickUpdateStatus(EstimateModel estimate, EstimateStatus status) async {
    await DbProvider.update(
      DbProvider.tableEstimates,
      {
        'status': status.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [estimate.id],
    );
    await _loadData();
  }

  Future<void> _convertToInvoice(EstimateModel estimate) async {
    final confirm = await AppDialog.showConvertEstimate(
      context: context,
      estimateNumber: estimate.estimateNumber,
      clientName: estimate.clientName,
    );

    if (confirm != true) return;

    try {
      final nextInvNumber = await DbProvider.getNextInvoiceNumber();
      final newInvoiceId = const Uuid().v4();

      final invoice = estimate.toInvoiceModel(
        newInvoiceId: newInvoiceId,
        newInvoiceNumber: nextInvNumber,
      );

      await DbProvider.insert(DbProvider.tableInvoices, invoice.toMap());
      for (int i = 0; i < invoice.lineItems.length; i++) {
        final item = invoice.lineItems[i];
        await DbProvider.insert(DbProvider.tableLineItems, {
          'id': item.id,
          'invoice_id': invoice.id,
          'description': item.description,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
          'sort_order': i,
        });
      }

      await DbProvider.update(
        DbProvider.tableEstimates,
        {
          'status': EstimateStatus.converted.value,
          'converted_invoice_id': newInvoiceId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        'id = ?',
        [estimate.id],
      );

      final prefs = await SharedPreferences.getInstance();
      final estimateCustomization = prefs.getString('estimate_customization_${estimate.id}');
      if (estimateCustomization != null) {
        await prefs.setString('invoice_customization_$newInvoiceId', estimateCustomization);
      }
      final estimateTheme = prefs.getString('estimate_theme_${estimate.id}');
      if (estimateTheme != null) {
        await prefs.setString('invoice_theme_$newInvoiceId', estimateTheme);
      }

      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Converted to Invoice $nextInvNumber!'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePreviewScreen(invoice: invoice),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(EstimateModel estimate) async {
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
        upiId: prefs.getString('biz_upi'),
        logoPath: prefs.getString('biz_logo_path'),
        signaturePath: prefs.getString('biz_signature_path'),
        currency: estimate.currency,
        invoiceTitleOverride: 'ESTIMATE',
      );

      final savedThemeId = prefs.getString('estimate_theme_${estimate.id}') ??
          prefs.getString('default_pdf_theme');
      final theme = PdfTheme.fromId(savedThemeId);

      final pdfBytes = await PdfGeneratorService.generateEstimatePdf(
        estimate: estimate,
        businessProfile: profile,
        isPro: isPro,
        theme: theme,
      );

      final path = await PdfGeneratorService.saveAndGetPath(
        pdfBytes,
        estimate.estimateNumber,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Estimate ${estimate.estimateNumber} for ${estimate.clientName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _deleteEstimate(EstimateModel estimate) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Estimate?',
      message: 'Are you sure you want to delete ${estimate.estimateNumber}? This action cannot be undone.',
    );

    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableEstimates, 'id = ?', [estimate.id]);
      await _loadData();
    }
  }

  Color _getAvatarColor(String name) {
    const colors = [
      AppColors.badgeOrange,
      AppColors.badgePink,
      AppColors.badgeViolet,
      AppColors.badgeEmerald,
      AppColors.badgeBlue,
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencyCode = currencyProvider.currencyCode;
    final currencySymbol = currencyProvider.currencySymbol;
    final isPro = context.watch<BillingService>().isPro;
    final filtered = _filteredEstimates;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search estimate or client...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.mutedSoft, fontSize: 15),
                ),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'Estimates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.ink,
              size: 20,
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
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards: Total Estimated / Pending / Accepted
                    Row(
                      children: [
                        // Card 1: Total Estimated
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12), // rounded.lg
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(
                                    _totalEstimated,
                                    currencyCode: currencyCode,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Card 2: Pending
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(
                                    _totalPending,
                                    currencyCode: currencyCode,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusOverdue,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Card 3: Accepted
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Accepted',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(
                                    _totalAccepted,
                                    currencyCode: currencyCode,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusPaid,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Chips Row (nav-pill container)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            _buildFilterChip('pending', 'Pending'),
                            _buildFilterChip('accepted', 'Accepted'),
                            _buildFilterChip('converted', 'Converted'),
                            _buildFilterChip('declined', 'Declined'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Estimates List or Clean Empty State
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.request_quote_outlined,
                  title: _searchQuery.isEmpty ? 'No Estimates Yet' : 'No Results Found',
                  subtitle: _searchQuery.isEmpty
                      ? 'Create and send quotes or proposals to prospective clients'
                      : 'Try adjusting your search query or filter',
                  actionLabel: _searchQuery.isEmpty ? 'Create Estimate' : null,
                  onAction: _searchQuery.isEmpty ? _createNewEstimate : null,
                  isDarkBackground: false,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final est = filtered[index];
                      return StaggeredEntrance(
                        index: index,
                        child: _buildEstimateCard(est),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: filtered.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 86),
              child: FloatingActionButton.extended(
                heroTag: 'estimate_list_fab',
                onPressed: _createNewEstimate,
                icon: const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 18),
                label: const Text(
                  'New Estimate',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onPrimary, fontSize: 13),
                ),
                backgroundColor: AppColors.primary,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9999), // pill
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.onPrimary : AppColors.body,
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateCard(EstimateModel estimate) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final avatarColor = _getAvatarColor(estimate.clientName);
    final initials = _getInitials(estimate.clientName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12), // rounded.lg
        border: Border.all(color: AppColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openEstimatePreview(estimate),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Left: Client Name & Estimate Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estimate.clientName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${estimate.estimateNumber} • ${dateFormat.format(estimate.estimateDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Amount + Status Pill + 3-dots Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        estimate.grandTotal,
                        currencyCode: estimate.currency.isNotEmpty
                            ? estimate.currency
                            : _currency,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estimate.status.backgroundColor,
                        borderRadius: BorderRadius.circular(9999), // pill
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estimate.status.icon, size: 10, color: estimate.status.color),
                          const SizedBox(width: 3),
                          Text(
                            estimate.status.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: estimate.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    switch (val) {
                      case 'convert':
                        _convertToInvoice(estimate);
                        break;
                      case 'preview':
                        _openEstimatePreview(estimate);
                        break;
                      case 'share':
                        _sharePdf(estimate);
                        break;
                      case 'accepted':
                        _quickUpdateStatus(estimate, EstimateStatus.accepted);
                        break;
                      case 'declined':
                        _quickUpdateStatus(estimate, EstimateStatus.declined);
                        break;
                      case 'pending':
                        _quickUpdateStatus(estimate, EstimateStatus.pending);
                        break;
                      case 'delete':
                        _deleteEstimate(estimate);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (estimate.canConvert)
                      AppPopupMenuItem.item(
                        value: 'convert',
                        title: 'Convert to Invoice',
                        icon: Icons.transform_rounded,
                        iconColor: AppColors.statusPaid,
                        iconBgColor: AppColors.statusPaidBg,
                      ),
                    AppPopupMenuItem.item(
                      value: 'preview',
                      title: 'View Details',
                      icon: Icons.visibility_outlined,
                    ),
                    AppPopupMenuItem.item(
                      value: 'share',
                      title: 'Share PDF',
                      icon: Icons.share_outlined,
                    ),
                    AppPopupMenuItem.divider(),
                    AppPopupMenuItem.item(
                      value: 'accepted',
                      title: 'Mark Accepted',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.statusPaid,
                      iconBgColor: AppColors.statusPaidBg,
                    ),
                    AppPopupMenuItem.item(
                      value: 'declined',
                      title: 'Mark Declined',
                      icon: Icons.cancel_outlined,
                      iconColor: AppColors.statusOverdue,
                      iconBgColor: AppColors.statusOverdueBg,
                    ),
                    AppPopupMenuItem.divider(),
                    AppPopupMenuItem.item(
                      value: 'delete',
                      title: 'Delete Estimate',
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

