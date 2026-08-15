import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';

class WorkstationSheet extends StatefulWidget {
  final String? initialName;
  final String? initialReaderId;
  final List<dynamic> allReaders;
  final List<dynamic> assignments;

  const WorkstationSheet({
    super.key,
    this.initialName,
    this.initialReaderId,
    required this.allReaders,
    required this.assignments,
  });

  @override
  State<WorkstationSheet> createState() => _WorkstationSheetState();
}

class _WorkstationSheetState extends State<WorkstationSheet> {
  late TextEditingController _nameController;
  late TextEditingController _manualIdController;
  bool _showTerminalSelection = false;
  bool _showManualEntry = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _manualIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _showTerminalSelection ? 'SumUp Terminal hinzufügen' : 'Neuer Arbeitsplatz',
            style: const TextStyle(
              fontSize: AppTheme.medium,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppTheme.surface),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: !_showTerminalSelection ? _buildNamingStep() : _buildTerminalStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildNamingStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                autofocus: true,
                cursorColor: AppTheme.white,
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(
                  hintText: 'z.B. Tresen Mitte',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            AppTheme.buildPrimaryButton(
              text: 'Weiter',
              color: AppTheme.active,
              width: 100,
              onTap: () {
                if (_nameController.text.isNotEmpty) {
                  setState(() => _showTerminalSelection = true);
                }
              },
            ),
          ],
        ),
        if (widget.initialReaderId != null) ...[
          const SizedBox(height: 24),
          AppTheme.buildPrimaryButton(
            text: 'Löschen',
            color: AppTheme.unpaid,
            onTap: () async {
              setState(() => _isSaving = true);
              try {
                await SumUpService().removeAssignment(widget.initialReaderId!);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                _showError(e.toString());
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTerminalStep() {
    if (_showManualEntry) return _buildManualEntryStep();

    final assignedIds = widget.assignments.map((a) => a['reader_id']).toSet();
    final availableReaders = widget.allReaders.where((r) {
      if (widget.initialReaderId != null && r['id'] == widget.initialReaderId) return true;
      return !assignedIds.contains(r['id']);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (availableReaders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Keine freien Terminals gefunden.', style: TextStyle(color: AppTheme.white)),
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
                      await SumUpService().assignTerminal(_nameController.text, reader['id'], name);
                      if (mounted) Navigator.pop(context, true);
                    } catch (e) {
                      _showError(e.toString());
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _showManualEntry = true),
          child: const Text('Reader-ID manuell eingeben', style: TextStyle(color: AppTheme.active, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildManualEntryStep() {
    return Column(
      children: [
        const Text(
          'Gib die Reader-ID deines SumUp Solo ein (z.B. rdr_...). Du findest diese in deinem SumUp Dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.free, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualIdController,
                autofocus: true,
                cursorColor: AppTheme.white,
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(
                  hintText: 'Reader-ID eingeben',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surface)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.white)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            AppTheme.buildPrimaryButton(
              text: 'Speichern',
              color: AppTheme.active,
              width: 100,
              onTap: () async {
                if (_manualIdController.text.isNotEmpty) {
                  setState(() => _isSaving = true);
                  try {
                    await SumUpService().assignTerminal(
                      _nameController.text, 
                      _manualIdController.text, 
                      'Manuelles Terminal'
                    );
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    _showError(e.toString());
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _showManualEntry = false),
          child: const Text('Zurück zur Liste', style: TextStyle(color: AppTheme.free)),
        ),
      ],
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $msg'), backgroundColor: AppTheme.unpaid),
      );
    }
  }
}
