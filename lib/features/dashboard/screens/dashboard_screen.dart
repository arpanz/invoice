import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/ads/banner_ad_widget.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/services/pdf_generator_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<InvoiceModel> _recentInvoices = [];
  double _totalOutstanding = 0;
  double _paidThisMonth = 0;
  double _totalOverdue = 0;
  bool _isLoading = true;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final currencyProvider = context.read<CurrencyProvider>();
    _currency = currencyProvider.currencyCode;

    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      orderBy: 'created_at DESC',
    );

    final invoices = <InvoiceModel>[];
    for (final row in rows) {
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [row['id']],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      invoices.add(InvoiceModel.fromMap(row, items: items));
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    double outstanding = 0;
    double paidThisMonth = 0;
    double overdue = 0;

    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.unpaid) {
        outstanding += inv.grandTotal;
        if (inv.isOverdue) overdue += inv.grandTotal;
      } else if (inv.status == InvoiceStatus.paid) {
        if (inv.updatedAt.isAfter(startOfMonth)) {
          paidThisMonth += inv.grandTotal;
        }
      }
    }

    setState(() {
      _recentInvoices = invoices.take(5).toList();
      _totalOutstanding = outstanding;
      _paidThisMonth = paidThisMonth;
      _totalOverdue = overdue;
      _isLoading = false;
    });
  }

  Future<void> _previewInvoice(InvoiceModel invoice) async {
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

    final pdfBytes = await PdfGeneratorService.generateInvoicePdf(
      invoice: invoice,
      businessProfile: profile,
      isPro: isPro,
    );

    if (mounted) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencySymbol = currencyProvider.currencySymbol;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Invoice Maker Pro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_outlined),
                  color: AppColors.slate500,
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Outstanding Card ─────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet_outlined,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Total Outstanding',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(
                                    _totalOutstanding,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Awaiting payment from clients',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Metrics Row ──────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  label: 'Paid This Month',
                                  value: CurrencyFormatter.format(
                                    _paidThisMonth,
                                    currencySymbol: currencySymbol,
                                  ),
                                  icon: Icons.check_circle_outline,
                                  iconColor: AppColors.statusPaid,
                                  bgColor: AppColors.statusPaidBg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  label: 'Overdue',
                                  value: CurrencyFormatter.format(
                                    _totalOverdue,
                                    currencySymbol: currencySymbol,
                                  ),
                                  icon: Icons.warning_amber_outlined,
                                  iconColor: AppColors.statusOverdue,
                                  bgColor: AppColors.statusOverdueBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── New Invoice Button ───────────────────────────
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                            ).then((_) => _loadData()),
                            icon: const Icon(Icons.add, size: 22),
                            label: const Text(
                              '+ New Invoice',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Recent Invoices ──────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Invoices',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_recentInvoices.isNotEmpty)
                                Text(
                                  '${_recentInvoices.length} shown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_recentInvoices.isEmpty)
                            EmptyStateView(
                              icon: Icons.receipt_long_outlined,
                              title: 'No Invoices Yet',
                              subtitle: 'Tap "+ New Invoice" to create your first invoice',
                            )
                          else
                            ...List.generate(_recentInvoices.length, (index) {
                              final invoice = _recentInvoices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildRecentInvoiceCard(invoice, currencySymbol),
                              );
                            }),

                          const SizedBox(height: 16),

                          // ── Banner Ad ────────────────────────────────────
                          const BannerAdWidget(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoiceCard(InvoiceModel invoice, String currencySymbol) {
    final dateFormat = DateFormat('dd MMM');

    Color statusBg;
    Color statusText;
    String statusLabel;

    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusBg = AppColors.statusPaidBg;
        statusText = AppColors.statusPaid;
        statusLabel = 'Paid';
        break;
      case InvoiceStatus.overdue:
        statusBg = AppColors.statusOverdueBg;
        statusText = AppColors.statusOverdue;
        statusLabel = 'Overdue';
        break;
      default:
        statusBg = AppColors.statusUnpaidBg;
        statusText = AppColors.statusUnpaid;
        statusLabel = 'Unpaid';
    }

    return GestureDetector(
      onTap: () => _previewInvoice(invoice),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_outlined, size: 20, color: AppColors.slate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${invoice.invoiceNumber} • ${dateFormat.format(invoice.invoiceDate)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(invoice.grandTotal, currencySymbol: currencySymbol),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
