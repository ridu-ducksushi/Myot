import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare/data/services/vaccination_schedule_service.dart';

class VaccineCard extends StatelessWidget {
  const VaccineCard({
    super.key,
    required this.item,
    this.onComplete,
  });

  final VaccineItem item;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(colorScheme);
    final statusBgColor = _statusBgColor(colorScheme);
    final statusIcon = _statusIcon();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: item.status == 'overdue'
            ? BorderSide(color: colorScheme.error.withOpacity(0.3))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Vaccine info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: item.status == 'completed'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(item.dueDate),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: item.status == 'overdue'
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: item.status == 'overdue'
                                      ? FontWeight.w600
                                      : null,
                                ),
                      ),
                      const SizedBox(width: 8),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (item.status == 'overdue') ...[
                    const SizedBox(height: 4),
                    Text(
                      _overdueDaysText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Complete button (only for non-completed items)
            if (item.status != 'completed' && onComplete != null)
              FilledButton.tonal(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'vaccination.complete'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

            // Check icon for completed
            if (item.status == 'completed')
              Icon(
                Icons.check_circle,
                color: colorScheme.tertiary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme) {
    switch (item.status) {
      case 'overdue':
        return colorScheme.error;
      case 'completed':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
  }

  Color _statusBgColor(ColorScheme colorScheme) {
    switch (item.status) {
      case 'overdue':
        return colorScheme.errorContainer;
      case 'completed':
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.primaryContainer;
    }
  }

  IconData _statusIcon() {
    switch (item.status) {
      case 'overdue':
        return Icons.warning_rounded;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case 'overdue':
        return 'vaccination.status_overdue'.tr();
      case 'completed':
        return 'vaccination.status_completed'.tr();
      default:
        return 'vaccination.status_upcoming'.tr();
    }
  }

  String _overdueDaysText() {
    final now = DateTime.now();
    final days = now.difference(item.dueDate).inDays;
    if (days == 0) {
      return 'vaccination.due_today'.tr();
    }
    return 'vaccination.overdue_days'.tr(args: ['$days']);
  }
}
