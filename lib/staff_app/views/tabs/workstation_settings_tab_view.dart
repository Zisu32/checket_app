import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_list_view.dart';
import '../../../../shared/services/sumup_service.dart';
import '../../widgets/workstation_sheet.dart';
import '../../widgets/workstation_action_sheet.dart';

class WorkstationSettingsTabView extends StatefulWidget {
  const WorkstationSettingsTabView({super.key});

  @override
  State<WorkstationSettingsTabView> createState() => _WorkstationSettingsTabViewState();
}

class _WorkstationSettingsTabViewState extends State<WorkstationSettingsTabView> {
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
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: 'Fehler beim Laden: $e'));
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

    return Column(
      children: [
        AppHeader(
          icon: Icons.tablet_android,
          actionText: 'Neuer Arbeitsplatz',
          onActionTap: () => _openWorkstationSheet(),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
            : AppListView<dynamic>(
                items: _assignments,
                onRefresh: _loadData,
                emptyMessage: 'Noch kein Arbeitsplatz eingerichtet',
                titleBuilder: (asg) => Text(
                  asg['station_name'],
                  style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: AppTheme.small),
                ),
                subtitleBuilder: (asg) => Text(
                  '${asg['reader_name']}',
                  style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.xsmall),
                ),
                trailingBuilder: (asg) => IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => WorkstationActionSheet(
                        assignment: asg,
                        isCurrent: asg['reader_id'] == localReaderId,
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
        ),
      ],
    );
  }
}
