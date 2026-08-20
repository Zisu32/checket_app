import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../widgets/user_action_sheet.dart';

class UserTabView extends StatefulWidget {
  const UserTabView({super.key});

  @override
  State<UserTabView> createState() => _UserTabViewState();
}

class _UserTabViewState extends State<UserTabView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _tenants = [];
  String? _filterTenant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Load Tenants for filtering and assignment
      final tenantData = await _supabase.from('tenants').select().order('name');
      
      // 2. Load Users via Edge Function
      final response = await _supabase.functions.invoke('manage-users', body: {'action': 'list'});
      
      if (!mounted) return;
      setState(() {
        _tenants = tenantData as List;
        _users = response.data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: AppTheme.unpaid)
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.functions.invoke('manage-users', body: {
        'action': 'delete',
        'userId': userId
      });
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen: $e'), backgroundColor: AppTheme.unpaid)
      );
      setState(() => _isLoading = false);
    }
  }

  void _showUserSheet([dynamic user]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (_) => UserActionSheet(
        user: user,
        tenants: _tenants,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
        _buildFilter(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
            : _buildList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.people_alt_rounded, color: AppTheme.white, size: 28),
            AppTheme.buildPrimaryButton(
              text: 'Neuer User',
              color: AppTheme.active,
              onTap: () => _showUserSheet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(color: AppTheme.free)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.surface),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: _filterTenant,
                hint: const Text('Alle Mandanten', style: TextStyle(color: AppTheme.free, fontSize: 14)),
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.white, fontSize: 14),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Alle anzeigen')),
                  ..._tenants.map((t) => DropdownMenuItem<String>(
                    value: t['schema_name'],
                    child: Text(t['name']),
                  )),
                ],
                onChanged: (val) => setState(() => _filterTenant = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final filteredUsers = _filterTenant == null 
        ? _users 
        : _users.where((u) => u['tenantSchema'] == _filterTenant).toList();

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'Keine Benutzer gefunden',
          style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return Card(
            color: AppTheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(user['email'] ?? 'Keine E-Mail', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${user['tenantName']} • ${user['role']}', style: const TextStyle(color: AppTheme.free)),
              trailing: IconButton(
                icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                onPressed: () => _showUserActions(user),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUserActions(dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.active),
              title: const Text('Bearbeiten', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showUserSheet(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.unpaid),
              title: const Text('Löschen', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteUser(user['id']);
              },
            ),
          ],
        ),
      ),
    );
  }
}
