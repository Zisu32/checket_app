import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';

class TerminalSelectionSheet extends StatefulWidget {
  final String stationName;
  final List<dynamic> allReaders;
  final List<dynamic> assignments;

  const TerminalSelectionSheet({
    super.key,
    required this.stationName,
    required this.allReaders,
    required this.assignments,
  });

  @override
  State<TerminalSelectionSheet> createState() => _TerminalSelectionSheetState();
}

class _TerminalSelectionSheetState extends State<TerminalSelectionSheet> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Filter out readers that are already assigned to other stations
    final assignedIds = widget.assignments.map((a) => a['reader_id']).toSet();
    final availableReaders = widget.allReaders.where((r) => !assignedIds.contains(r['id'])).toList();

    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SumUp Terminal hinzufügen',
            style: const TextStyle(
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'für Arbeitsstation: ${widget.stationName}',
            style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.small),
          ),
          const SizedBox(height: 16),
          const Divider(height: 24, indent: 20, endIndent: 20, color: AppTheme.surface),
          const SizedBox(height: 8),

          if (availableReaders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Keine verfügbaren Terminals gefunden.', style: TextStyle(color: AppTheme.white)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableReaders.length,
                itemBuilder: (context, index) {
                  final reader = availableReaders[index];
                  final name = reader['name'] ?? 'Unbekanntes Solo';
                  
                  return ListTile(
                    leading: const Icon(Icons.tablet_android, color: AppTheme.active),
                    title: Text(name, style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small)),
                    subtitle: Text(reader['id'], style: const TextStyle(color: AppTheme.free, fontSize: 12)),
                    trailing: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    onTap: _isSaving ? null : () async {
                      setState(() => _isSaving = true);
                      try {
                        await SumUpService().assignTerminal(widget.stationName, reader['id'], name);
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fehler: $e'), backgroundColor: AppTheme.unpaid)
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
