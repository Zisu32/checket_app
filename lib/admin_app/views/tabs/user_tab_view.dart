import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_action_sheet.dart';
import '../../../shared/widgets/app_list_view.dart';
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
      final tenantData = await _supabase.from('tenants').select().order('name');
      final response = await _supabase.functions.invoke('manage-users', body: {'action': 'list'});
      
      if (!mounted) return;
      setState(() {
        _tenants = tenantData as List;
        _users = response.data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler beim Laden: $e'));
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler beim Löschen: $e'));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showUserSheet([dynamic user]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
    final filteredUsers = _filterTenant == null 
        ? _users 
        : _users.where((u) => u['tenantSchema'] == _filterTenant).toList();

    return Column(
      children: [
        AppHeader(
          icon: Icons.people_alt_rounded,
          actionText: 'Neuer User',
          onActionTap: () => _showUserSheet(),
        ),
        _buildFilter(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
            : AppListView<dynamic>(
                items: filteredUsers,
                onRefresh: _loadData,
                emptyMessage: 'Keine Benutzer gefunden',
                titleBuilder: (u) => Text(u['email'] ?? 'Keine E-Mail', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                subtitleBuilder: (u) => Text('${u['tenantName']} • ${u['role']}', style: const TextStyle(color: AppTheme.free)),
                trailingBuilder: (u) => IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                  onPressed: () => _showUserActions(u),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(color: AppTheme.free)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.surface),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _filterTenant,
                hint: const Text('Alle Tenants', style: TextStyle(color: AppTheme.free, fontSize: 14)),
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

  void _showUserActions(dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppActionSheet(
        title: user['email'] ?? 'Benutzer',
        subtitle: 'Mitarbeiter verwalten',
        actions: [
          SheetAction(
            icon: Icons.edit,
            label: 'Bearbeiten',
            color: AppTheme.active,
            onTap: () {
              Navigator.pop(ctx);
              _showUserSheet(user);
            },
          ),
          SheetAction(
            icon: Icons.close,
            label: 'Löschen',
            color: AppTheme.unpaid,
            onTap: () {
              Navigator.pop(ctx);
              _deleteUser(user['id']);
            },
          ),
        ],
      ),
    );
  }
}
