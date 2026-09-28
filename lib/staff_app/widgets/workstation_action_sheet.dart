import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_action_sheet.dart';

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
    return AppActionSheet(
      title: assignment['station_name'],
      subtitle: 'Arbeitsplatz verwalten',
      actions: [
        if (!isCurrent)
          SheetAction(
            icon: Icons.check_circle_outline_rounded,
            label: 'Aktivieren',
            color: AppTheme.active,
            onTap: () {
              Navigator.pop(context);
              onActivate();
            },
          ),
        SheetAction(
          icon: Icons.edit_rounded,
          label: 'Bearbeiten',
          color: isCurrent ? AppTheme.active : AppTheme.white,
          onTap: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        SheetAction(
          icon: Icons.close,
          label: 'Löschen',
          color: AppTheme.unpaid,
          onTap: () {
            Navigator.pop(context);
            _showConfirmDelete(context);
          },
        ),
      ],
    );
  }

  void _showConfirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppActionSheet(
        title: 'Wirklich löschen?',
        subtitle: 'Der Arbeitsplatz wird dauerhaft entfernt.',
        actions: [
          SheetAction(
            icon: Icons.close,
            label: 'Ja, löschen',
            color: AppTheme.unpaid,
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
