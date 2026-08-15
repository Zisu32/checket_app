import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';
import '../widgets/terminal_selection_sheet.dart';

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
    setState(() => _isLoading = true);
    try {
      final status = await _sumUpService.getTerminalStatus();
      setState(() {
        _readers = status['readers'] ?? [];
        _assignments = status['assignments'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: AppTheme.unpaid)
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _addTerminal(String stationName) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (context) => TerminalSelectionSheet(
        stationName: stationName,
        allReaders: _readers,
        assignments: _assignments,
      ),
    );
    if (success == true) _loadData();
  }

  void _createNewStation() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Neue Arbeitsstation', style: TextStyle(color: AppTheme.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.white),
          decoration: const InputDecoration(
            hintText: 'Z.B. Tresen Mitte',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _addTerminal(controller.text);
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localReaderId = _sumUpService.getSelectedReaderId();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.header,
        elevation: 0,
        title: const Text('Arbeitsstationen & Terminals', style: TextStyle(fontSize: AppTheme.small, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.active))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_assignments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Noch keine Stationen eingerichtet.', style: TextStyle(color: AppTheme.free))),
                  )
                else
                  ..._assignments.map((asg) {
                    final isCurrent = asg['reader_id'] == localReaderId;
                    return Card(
                      color: AppTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isCurrent ? const BorderSide(color: AppTheme.active, width: 2) : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(asg['station_name'], style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Terminal: ${asg['reader_name']}', style: const TextStyle(color: AppTheme.free, fontSize: 13)),
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
                                child: const Text('Aktivieren', style: TextStyle(color: AppTheme.active)),
                              )
                            else
                              const Icon(Icons.check_circle, color: AppTheme.active),
                            
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.unpaid),
                              onPressed: () async {
                                await _sumUpService.removeAssignment(asg['reader_id']);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),
                Center(
                  child: AppTheme.buildPrimaryButton(
                    text: 'Neue Station hinzufügen',
                    color: AppTheme.active,
                    onTap: _createNewStation,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
