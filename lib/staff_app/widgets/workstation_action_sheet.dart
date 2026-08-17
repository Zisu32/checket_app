import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/services/sumup_service.dart';

class WorkstationActionSheet extends StatelessWidget {
  final dynamic assignment;
  final bool isCurrent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onActivate;

  const WorkstationActionSheet({
    super.key,
    required this.assignment,
    required this.isCurrent,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
  });

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
          const Text(
            'Bearbeiten',
            style: TextStyle(
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
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isCurrent ? Icons.create_rounded : Icons.check,
                    color: AppTheme.active,
                  ),
                  title: Text(
                    isCurrent ? 'Bearbeiten' : 'Aktivieren',
                    style: const TextStyle(fontSize: AppTheme.small, color: AppTheme.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (isCurrent) {
                      onEdit();
                    } else {
                      onActivate();
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.close, color: AppTheme.unpaid),
                  title: const Text(
                    'Löschen',
                    style: TextStyle(fontSize: AppTheme.small, color: AppTheme.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wirklich löschen?',
              style: TextStyle(
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
              child: AppTheme.buildPrimaryButton(
                icon: Icons.close,
                text: 'Ja, löschen',
                color: AppTheme.unpaid,
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
