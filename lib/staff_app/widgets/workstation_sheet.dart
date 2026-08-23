import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/app_primary_button.dart';
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
  bool _showTerminalSelection = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (!_showTerminalSelection) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 64,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\/]')),
              ],
              cursorColor: AppTheme.white,
              style: const TextStyle(color: AppTheme.white),
              decoration: const InputDecoration(
                labelText: 'Name des Arbeitsplatzes',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 16),
          AppPrimaryButton(
            text: 'Weiter',
            color: AppTheme.active,
            onTap: () {
              if (_nameController.text.isNotEmpty) {
                FocusScope.of(context).unfocus();
                setState(() => _showTerminalSelection = true);
              }
            },
          ),
        ],
      );
    } else {
      // Step 2: Terminal Selection
      final assignedIds = widget.assignments
          .map((a) => a is Map ? a['reader_id'] : null)
          .whereType<String>()
          .toSet();

      final availableReaders = widget.allReaders.where((r) {
        if (r is! Map) return false;
        if (widget.initialReaderId != null && r['id'] == widget.initialReaderId) return true;
        return !assignedIds.contains(r['id']);
      }).toList();

      if (availableReaders.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Keine freien Terminals gefunden.',
            style: TextStyle(color: AppTheme.white),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: availableReaders.map((reader) {
          final name = reader['name'] ?? 'Unbekanntes Solo';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tablet_android, color: AppTheme.active),
            title: Text(name, style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small)),
            subtitle: Text(reader['id'], style: const TextStyle(color: AppTheme.free, fontSize: AppTheme.xsmall)),
            trailing: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.active)) 
                : null,
            onTap: _isSaving ? null : () async {
              setState(() => _isSaving = true);
              try {
                await SumUpService().assignTerminal(_nameController.text, reader['id'], name);
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                _showError(e.toString());
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
          );
        }).toList(),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(message: 'Fehler: $msg', isError: true),
      );
    }
  }
}
