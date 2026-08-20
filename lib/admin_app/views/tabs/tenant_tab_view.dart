import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: AppTheme.unpaid)
        );
        setState(() => _isLoading = false);
      }
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
            const Icon(Icons.warehouse_rounded, color: AppTheme.white, size: 28),
            AppTheme.buildPrimaryButton(
              text: 'Neuer Tenant',
              color: AppTheme.active,
              onTap: () => _showTenantSheet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_tenants.isEmpty) {
      return const Center(
        child: Text(
          'Keine Mandanten gefunden',
          style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTenants,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _tenants.length,
        itemBuilder: (context, index) {
          final t = _tenants[index];
          return Card(
            color: AppTheme.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(t['name'], style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              subtitle: Text(t['schema_name'], style: const TextStyle(color: AppTheme.free)),
              trailing: IconButton(
                icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                onPressed: () => _showTenantActions(t),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTenantActions(dynamic tenant) {
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
                _showTenantSheet(tenant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.unpaid),
              title: const Text('Löschen', style: TextStyle(color: AppTheme.white)),
              onTap: () async {
                Navigator.pop(ctx);
                // Implementation of delete logic could be added here
              },
            ),
          ],
        ),
      ),
    );
  }
}
