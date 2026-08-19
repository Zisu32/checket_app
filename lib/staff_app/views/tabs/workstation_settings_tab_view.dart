import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/services/sumup_service.dart';
import '../../../../shared/services/sync_service.dart';
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.active));
    }

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.tablet_android, color: AppTheme.white, size: 28),
                AppTheme.buildPrimaryButton(
                  text: 'Neuer Arbeitsplatz',
                  color: AppTheme.active,
                  onTap: () => _openWorkstationSheet(),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
        Expanded(
          child: _assignments.isEmpty
              ? const Center(
                  child: Text(
                    'Noch kein Arbeitsplatz eingerichtet',
                    style: TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final asg = _assignments[index];
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
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
