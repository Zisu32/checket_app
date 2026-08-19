import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../widgets/top_bar.dart';
import '../../shared/services/sync_service.dart';
import '../widgets/tenant_action_sheet.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TopBar(
        syncService: SyncService(),
        pulseAnimation: const AlwaysStoppedAnimation(1.0),
        showSettings: false,
        leading: const SizedBox.shrink(), // No back button for admin main
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.white, size: 24),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
              : _buildList(),
          ),
        ],
      ),
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
            const Icon(Icons.menu_open_rounded, color: AppTheme.white, size: 28),
            AppTheme.buildPrimaryButton(
              text: 'Neuer Mandant',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _tenants.length,
        itemBuilder: (context, index) {
          final t = _tenants[index];
          return Card(
            color: AppTheme.surface,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(t['name'], style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              subtitle: Text(t['schema_name'], style: const TextStyle(color: AppTheme.free)),
              trailing: IconButton(
                icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                onPressed: () => _showTenantSheet(t),
              ),
            ),
          );
        },
      ),
    );
  }
}
