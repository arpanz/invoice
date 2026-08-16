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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convert to Invoice?'),
        content: Text('Convert ${estimate.estimateNumber} for ${estimate.clientName} into an active Invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert'),
          ),
        ],
      ),
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

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Estimate ${estimate.estimateNumber} for ${estimate.clientName}',
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Estimate?'),
        content: Text('Are you sure you want to delete ${estimate.estimateNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableEstimates, 'id = ?', [estimate.id]);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(_currency);
    final filtered = _filteredEstimates;

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
                  hintText: 'Search client or estimate #...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.slate400, fontSize: 15),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'Estimates',
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.proGold),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currencySymbol${_totalEstimated.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currencySymbol${_totalPending.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF59E0B),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Accepted',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currencySymbol${_totalAccepted.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
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

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('pending', 'Pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('accepted', 'Accepted'),
                          const SizedBox(width: 8),
                          _buildFilterChip('converted', 'Converted'),
                          const SizedBox(width: 8),
                          _buildFilterChip('declined', 'Declined'),
                        ],
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final est = filtered[index];
                      return StaggeredEntrance(
                        index: index,
                        child: _buildEstimateCard(est, currencySymbol),
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
                onPressed: _createNewEstimate,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'New Estimate',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
                backgroundColor: AppColors.primary,
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateCard(EstimateModel estimate, String currencySymbol) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEstimatePreview(estimate),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Client Name & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        estimate.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$currencySymbol${estimate.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Middle row: Estimate #, Date, Expiry
                Row(
                  children: [
                    Text(
                      estimate.estimateNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.slate400)),
                    Text(
                      dateFormat.format(estimate.estimateDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                    if (estimate.expiryDate != null) ...[
                      const Text(' • ', style: TextStyle(color: AppColors.slate400)),
                      Text(
                        'Expires ${dateFormat.format(estimate.expiryDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: estimate.isExpired ? AppColors.accentRed : AppColors.slate500,
                          fontWeight: estimate.isExpired ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: Status badge & Actions popup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: estimate.status.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estimate.status.icon, size: 12, color: estimate.status.color),
                          const SizedBox(width: 4),
                          Text(
                            estimate.status.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: estimate.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.slate500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          const PopupMenuItem(
                            value: 'convert',
                            child: Row(
                              children: [
                                Icon(Icons.transform_rounded, size: 18, color: Color(0xFF10B981)),
                                SizedBox(width: 10),
                                Text('Convert to Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('View / Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Share PDF'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'accepted',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                              SizedBox(width: 10),
                              Text('Mark Accepted'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'declined',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('Mark Declined'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRed),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: AppColors.accentRed)),
                            ],
                          ),
                        ),
                      ],
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
