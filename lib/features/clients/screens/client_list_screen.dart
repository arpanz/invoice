import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_widgets/custom_text_field.dart';
import '../../../shared_widgets/empty_state_view.dart';
import '../../../shared_widgets/primary_button.dart';
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
    return _clients.where((c) =>
      c.name.toLowerCase().contains(q) ||
      (c.email?.toLowerCase().contains(q) ?? false) ||
      (c.phone?.contains(q) ?? false)
    ).toList();
  }

  Future<void> _showAddEditDialog({ClientModel? client}) async {
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Client Name *',
                hint: 'John Doe / Acme Corp',
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
        address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
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
    return Scaffold(
      appBar: widget.selectionMode
          ? AppBar(title: const Text('Select Client'))
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: CustomTextField(
              hint: 'Search clients...',
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Client list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? EmptyStateView(
                        icon: Icons.people_outline,
                        title: _searchQuery.isEmpty ? 'No Clients Yet' : 'No Results',
                        subtitle: _searchQuery.isEmpty
                            ? 'Add your first client to get started'
                            : 'Try a different search term',
                        actionLabel: _searchQuery.isEmpty ? 'Add Client' : null,
                        onAction: _searchQuery.isEmpty ? () => _showAddEditDialog() : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _filteredClients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final client = _filteredClients[index];
                          return _buildClientCard(client);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Client'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            client.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.email != null)
                Text(client.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (client.phone != null)
                Text(client.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          trailing: widget.selectionMode
              ? const Icon(Icons.chevron_right, color: AppColors.slate400)
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _showAddEditDialog(client: client);
                    if (value == 'delete') _deleteClient(client);
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
      ),
    );
  }
}
