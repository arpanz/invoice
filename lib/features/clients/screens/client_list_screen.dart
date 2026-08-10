import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_animations.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../paywall/paywall_screen.dart';
import '../models/client_model.dart';

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

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                client == null ? 'Add New Client' : 'Edit Client',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
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
                hint: '+91 98765 43210',
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
                label: 'GSTIN',
                hint: '22AAAAA0000A1Z5',
                controller: gstinCtrl,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to delete "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbProvider.delete(DbProvider.tableClients, 'id = ?', [client.id]);
      await _loadClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionMode ? 'Select Client' : 'Clients',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CustomTextField(
              hint: 'Search clients...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                ? EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No Clients Yet'
                        : 'No Results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Add your first client to get started'
                        : 'Try a different search term',
                    actionLabel: _searchQuery.isEmpty ? 'Add Client' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _showAddEditDialog()
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => StaggeredEntrance(
                      index: index,
                      child: _buildClientCard(filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Client', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    final initials = client.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: widget.selectionMode ? () => Navigator.pop(context, client) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryMuted,
            child: Text(
              initials.isEmpty ? 'CL' : initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            client.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.email != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 13, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      client.email!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (client.phone != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      client.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: widget.selectionMode
              ? const Icon(Icons.chevron_right_rounded, color: AppColors.primary)
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditDialog(client: client);
                    }
                    if (value == 'delete') _deleteClient(client);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.slate600),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRed),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.accentRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
