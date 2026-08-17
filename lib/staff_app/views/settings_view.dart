import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';
import '../../shared/services/sync_service.dart';
import '../widgets/workstation_sheet.dart';
import '../widgets/top_bar.dart';
import '../widgets/workstation_action_sheet.dart';
import 'admin_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  final _sumUpService = SumUpService();
  final _syncService = SyncService();
  bool _isLoading = true;
  List<dynamic> _readers = [];
  List<dynamic> _assignments = [];

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final status = await _sumUpService.getTerminalStatus();
      if (!mounted) return;
      setState(() {
        _readers = status['readers'] ?? [];
        _assignments = status['assignments'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e', style: const TextStyle(color: AppTheme.white)),
            backgroundColor: AppTheme.unpaid,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openWorkstationSheet({String? name, String? readerId}) async {
    await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (context) => WorkstationSheet(
        initialName: name,
        initialReaderId: readerId,
        allReaders: _readers,
        assignments: _assignments,
      ),
    );
    
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final localReaderId = _sumUpService.getSelectedReaderId();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TopBar(
        syncService: _syncService,
        pulseAnimation: _pulseAnimation,
        showSettings: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.white, size: 24),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (mounted) Navigator.pop(context);
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
                : _buildContent(localReaderId),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = user?.appMetadata['role'] == 'admin';

    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.settings_outlined, color: AppTheme.white, size: 28),
            Row(
              children: [
                if (isAdmin) ...[
                  AppTheme.buildPrimaryButton(
                    text: 'Plattform-Verwaltung',
                    color: AppTheme.secret.withValues(alpha: 0.8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminView())),
                  ),
                  const SizedBox(width: 8),
                ],
                AppTheme.buildPrimaryButton(
                  text: 'Neuer Arbeitsplatz',
                  color: AppTheme.active,
                  onTap: () => _openWorkstationSheet(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String? localReaderId) {
    if (_assignments.isEmpty) {
      return const Center(
        child: Text(
          'Noch kein Arbeitsplatz eingerichtet',
          style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          ..._assignments.map((asg) {
            final isCurrent = asg['reader_id'] == localReaderId;
            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrent ? const BorderSide(color: AppTheme.active, width: 2) : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  asg['station_name'],
                  style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: AppTheme.small),
                ),
                subtitle: Text(
                  '${asg['reader_name']}',
                  style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.xsmall),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.background,
                      isScrollControlled: true,
                      builder: (_) => WorkstationActionSheet(
                        assignment: asg,
                        isCurrent: isCurrent,
                        onActivate: () {
                          _sumUpService.setLocalStation(asg['station_name'], asg['reader_id']);
                          setState(() {});
                        },
                        onEdit: () => _openWorkstationSheet(
                          name: asg['station_name'],
                          readerId: asg['reader_id'],
                        ),
                        onDelete: () async {
                          await _sumUpService.removeAssignment(asg['reader_id']);
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
