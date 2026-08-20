import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_action_sheet.dart';
import '../../../shared/widgets/app_list_view.dart';
import '../../widgets/tenant_action_sheet.dart';

class TenantTabView extends StatefulWidget {
  const TenantTabView({super.key});

  @override
  State<TenantTabView> createState() => _TenantTabViewState();
}

class _TenantTabViewState extends State<TenantTabView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _tenants = [];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('tenants').select().order('name');
      if (!mounted) return;
      setState(() {
        _tenants = data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Fehler beim Laden: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTenant(String schemaName) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.functions.invoke('manage-users', body: {
        'action': 'delete-tenant',
        'schemaName': schemaName
      });
      await _loadTenants();
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Fehler beim Löschen: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _showTenantSheet([dynamic tenant]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (_) => TenantActionSheet(
        tenant: tenant,
        onSaved: _loadTenants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
            : AppListView<dynamic>(
                items: _tenants,
                onRefresh: _loadTenants,
                emptyMessage: 'Keine Tenants gefunden',
                titleBuilder: (t) => Text(t['name'], style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                subtitleBuilder: (t) => Text(t['schema_name'], style: const TextStyle(color: AppTheme.free)),
                trailingBuilder: (t) => IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                  onPressed: () => _showTenantActions(t),
                ),
              ),
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
            const Icon(Icons.warehouse_rounded, color: AppTheme.white, size: 28),
            AppPrimaryButton(
              text: 'Neuer Tenant',
              color: AppTheme.active,
              onTap: () => _showTenantSheet(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTenantActions(dynamic tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppActionSheet(
        title: tenant['name'],
        subtitle: 'Tenant verwalten',
        actions: [
          SheetAction(
            icon: Icons.edit,
            label: 'Bearbeiten',
            color: AppTheme.active,
            onTap: () {
              Navigator.pop(ctx);
              _showTenantSheet(tenant);
            },
          ),
          SheetAction(
            icon: Icons.close,
            label: 'Löschen',
            color: AppTheme.unpaid,
            onTap: () {
              Navigator.pop(ctx);
              _deleteTenant(tenant['schema_name']);
            },
          ),
        ],
      ),
    );
  }
}
