import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';
import '../widgets/workstation_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _sumUpService = SumUpService();
  bool _isLoading = true;
  List<dynamic> _readers = [];
  List<dynamic> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
    
    // Always reload data after sheet closes to ensure UI matches DB state
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final localReaderId = _sumUpService.getSelectedReaderId();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.header,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: SvgPicture.asset(
        'assets/images/full-icon.svg',
        height: 28,
        placeholderBuilder: (_) => const Text(
          'CHECKET',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white, fontSize: AppTheme.small),
        ),
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
            const Icon(Icons.settings_outlined, color: AppTheme.white, size: 28),
            AppTheme.buildPrimaryButton(
              text: 'Neuer Arbeitsplatz',
              color: AppTheme.active,
              onTap: () => _openWorkstationSheet(),
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final asg = _assignments[index];
          final isCurrent = asg['reader_id'] == localReaderId;

          return Card(
            color: AppTheme.surface,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                asg['station_name'],
                style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: AppTheme.small),
              ),
              subtitle: Text(
                '${asg['reader_name']}',
                style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrent)
                    TextButton(
                      onPressed: () {
                        _sumUpService.setLocalStation(asg['station_name'], asg['reader_id']);
                        setState(() {});
                      },
                      child: const Text('Aktivieren', style: TextStyle(color: AppTheme.active, fontWeight: FontWeight.bold)),
                    )
                  else
                  AppTheme.buildPrimaryButton(
                    text: 'Bearbeiten',
                    color: AppTheme.active,
                    width: null,
                    height: 40,
                    onTap: () => _openWorkstationSheet(
                      name: asg['station_name'],
                      readerId: asg['reader_id'],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
