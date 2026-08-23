import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/models/line_item_model.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../invoices/screens/invoice_preview_screen.dart';
import '../../paywall/paywall_screen.dart';
import '../models/client_model.dart';
import '../../../shared_widgets/app_dialog.dart';
import '../../../shared_widgets/app_popup_menu.dart';

class ClientListScreen extends StatefulWidget {
  final bool selectionMode;
  const ClientListScreen({super.key, this.selectionMode = false});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<ClientModel> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    final rows = await DbProvider.query(
      DbProvider.tableClients,
      orderBy: 'name ASC',
    );
    setState(() {
      _clients = rows.map(ClientModel.fromMap).toList();
      _isLoading = false;
    });
  }

  List<ClientModel> get _filteredClients {
    if (_searchQuery.isEmpty) return _clients;
    final q = _searchQuery.toLowerCase();
    return _clients
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              (c.email?.toLowerCase().contains(q) ?? false) ||
              (c.phone?.contains(q) ?? false),
        )
        .toList();
  }

  Future<void> _showAddEditDialog({ClientModel? client}) async {
    if (client == null) {
      final billing = context.read<BillingService>();
      if (!billing.isPro && _clients.length >= 5) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
        return;
      }
    }

    final nameCtrl = TextEditingController(text: client?.name ?? '');
    final emailCtrl = TextEditingController(text: client?.email ?? '');
    final phoneCtrl = TextEditingController(text: client?.phone ?? '');
    final addressCtrl = TextEditingController(text: client?.address ?? '');
    final gstinCtrl = TextEditingController(text: client?.gstin ?? '');
    final formKey = GlobalKey<FormState>();

    final currencyProvider = context.read<CurrencyProvider>();
    final taxIdLabel = currencyProvider.taxIdLabel;
    final taxIdHint = currencyProvider.taxIdHint;

    final result = await showModalBottomSheet<bool>(
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
          child: SingleChildScrollView(
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.squirclePurple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.squirclePurpleIcon,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client == null ? 'Add New Client' : 'Edit Client',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              client == null
                                  ? 'Save details for fast invoicing'
                                  : 'Update client information',
                              style: const TextStyle(
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
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Client Name *',
                  hint: 'John Doe / Acme Corp',
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Email',
                  hint: 'client@example.com',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Phone',
                  hint: '+1 (555) 012-3456',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Address',
                  hint: '123 Main St, City',
                  controller: addressCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: taxIdLabel,
                  hint: taxIdHint,
                  controller: gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: client == null ? 'Add Client' : 'Save Changes',
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final now = DateTime.now();
      final newClient = ClientModel(
        id: client?.id ?? const Uuid().v4(),
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        address: addressCtrl.text.trim().isEmpty
            ? null
            : addressCtrl.text.trim(),
        gstin: gstinCtrl.text.trim().isEmpty ? null : gstinCtrl.text.trim(),
        createdAt: client?.createdAt ?? now,
      );
      await DbProvider.insert(DbProvider.tableClients, newClient.toMap());
      await _loadClients();
    }
  }

  Future<void> _deleteClient(ClientModel client) async {
    final confirm = await AppDialog.showDelete(
      context: context,
      title: 'Delete Client?',
      message: 'Are you sure you want to delete "${client.name}"? This action cannot be undone.',
    );
    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableClients, 'id = ?', [client.id]);
      await _loadClients();
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
    final filtered = _filteredClients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: widget.selectionMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.selectionMode ? 'Select Client' : 'Clients',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(8), // rounded.md
                border: Border.all(color: AppColors.hairline),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.muted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        hintStyle: GoogleFonts.inter(color: AppColors.mutedSoft, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(color: AppColors.ink, fontSize: 14),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.people_outline_rounded,
                        title: _searchQuery.isEmpty
                            ? 'No Clients Yet'
                            : 'No Results',
                        subtitle: _searchQuery.isEmpty
                            ? 'Add your first client to start sending invoices'
                            : 'Try a different search term',
                        actionLabel: _searchQuery.isEmpty ? 'Add Client' : null,
                        onAction: _searchQuery.isEmpty
                            ? () => _showAddEditDialog()
                            : null,
                        isDarkBackground: false,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => StaggeredEntrance(
                          index: index,
                          child: _buildClientCard(filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: filtered.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 86),
              child: FloatingActionButton.extended(
                heroTag: 'client_list_fab',
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.person_add_rounded, color: AppColors.onPrimary, size: 18),
                label: Text(
                  'Add Client',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onPrimary, fontSize: 13),
                ),
                backgroundColor: AppColors.primary,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
            ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    final avatarColor = _getAvatarColor(client.name);
    final initials = _getInitials(client.name);

    return GestureDetector(
      onTap: widget.selectionMode
          ? () => Navigator.pop(context, client)
          : () => _showClientDetailSheet(client),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12), // rounded.lg
          border: Border.all(color: AppColors.hairline),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              client.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.email != null && client.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        client.email!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
                if (client.phone != null && client.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        client.phone!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: widget.selectionMode
                ? const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20)
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(client: client);
                      }
                      if (value == 'delete') _deleteClient(client);
                    },
                    itemBuilder: (_) => [
                      AppPopupMenuItem.item(
                        value: 'edit',
                        title: 'Edit Client',
                        icon: Icons.edit_outlined,
                      ),
                      AppPopupMenuItem.divider(),
                      AppPopupMenuItem.item(
                        value: 'delete',
                        title: 'Delete Client',
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }


  Future<void> _showClientDetailSheet(ClientModel client) async {
    HapticFeedback.lightImpact();
    // Query invoices for this client
    final invRows = await DbProvider.query(
      DbProvider.tableInvoices,
      where: 'client_name = ? OR (client_email IS NOT NULL AND client_email = ?)',
      whereArgs: [client.name, client.email ?? ''],
      orderBy: 'invoice_date DESC',
    );

    double totalInvoiced = 0.0;
    double totalPaid = 0.0;
    double totalDue = 0.0;
    final List<InvoiceModel> clientInvoices = [];

    for (final row in invRows) {
      final invoiceId = row['id'] as String;
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      final inv = InvoiceModel.fromMap(row, items: items);
      clientInvoices.add(inv);

      totalInvoiced += inv.grandTotal;
      if (inv.status == InvoiceStatus.paid) {
        totalPaid += inv.grandTotal;
      } else if (inv.status == InvoiceStatus.partiallyPaid) {
        totalPaid += inv.paidAmount;
        totalDue += inv.balanceDue;
      } else {
        totalDue += inv.grandTotal;
      }
    }

    if (!mounted) return;
    final currencyProvider = context.read<CurrencyProvider>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDetailState) {
          final initials = client.name
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryMuted,
                        child: Text(
                          initials.isEmpty ? 'CL' : initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (client.email != null && client.email!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                client.email!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        tooltip: 'Edit Client',
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _showAddEditDialog(client: client);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // KPI Revenue Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Invoiced', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalInvoiced,
                                  currencyCode: currencyProvider.currencyCode,
                                ),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusPaidBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.statusPaid.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusPaid)),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalPaid,
                                  currencyCode: currencyProvider.currencyCode,
                                ),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.statusPaid),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: totalDue > 0 ? AppColors.statusUnpaidBg : AppColors.slate100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: (totalDue > 0 ? AppColors.statusUnpaid : AppColors.slate300).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: totalDue > 0 ? AppColors.statusUnpaid : AppColors.slate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalDue,
                                  currencyCode: currencyProvider.currencyCode,
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: totalDue > 0 ? AppColors.statusUnpaid : AppColors.slate700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoices (${clientInvoices.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateInvoiceScreen(
                                prefilledClient: client,
                              ),
                            ),
                          ).then((_) => _loadClients());
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: clientInvoices.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.slate300),
                                SizedBox(height: 8),
                                Text('No invoices created for this client yet', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: clientInvoices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final inv = clientInvoices[idx];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvoicePreviewScreen(invoice: inv),
                                  ),
                                ).then((_) => _loadClients());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.invoiceNumber,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            inv.status.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: inv.status == InvoiceStatus.paid
                                                  ? AppColors.statusPaid
                                                  : inv.status == InvoiceStatus.overdue
                                                      ? AppColors.statusOverdue
                                                      : AppColors.statusUnpaid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        inv.grandTotal,
                                        currencyCode: inv.currency.isNotEmpty
                                            ? inv.currency
                                            : currencyProvider.currencyCode,
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.slate400),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
