import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import 'package:petcare/data/models/record.dart';

/// Timeline card with colored status dots for each symptom category.
///
/// Expandable to show details of the symptom record.
class SymptomTimelineCard extends StatefulWidget {
  const SymptomTimelineCard({
    super.key,
    required this.record,
    this.isFirst = false,
    this.isLast = false,
  });

  final Record record;
  final bool isFirst;
  final bool isLast;

  @override
  State<SymptomTimelineCard> createState() => _SymptomTimelineCardState();
}

class _SymptomTimelineCardState extends State<SymptomTimelineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final value = widget.record.value ?? {};
    final overallColor = _getOverallStatusColor(value);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Line above dot
                if (!widget.isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: colorScheme.outline.withOpacity(0.3),
                  )
                else
                  const SizedBox(height: 12),

                // Status dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: overallColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: overallColor.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),

                // Line below dot
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0.5,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(widget.record.at),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Symptom status dots
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _buildStatusDots(context, value),
                        ),

                        // Expanded details
                        if (_isExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildDetails(context, value),
                        ],

                        // Content note
                        if (widget.record.content != null &&
                            widget.record.content!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.record.content!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusDots(
      BuildContext context, Map<String, dynamic> value) {
    final items = <Widget>[];

    final categories = <String, dynamic>{
      'symptom.appetite': value['appetite'],
      'symptom.energy': value['energy'],
      'symptom.vomiting': value['vomiting'],
      'symptom.diarrhea': value['diarrhea'],
      'symptom.coughing': value['coughing'],
      'symptom.skin_condition': value['skin_condition'],
      'symptom.eye_discharge': value['eye_discharge'],
      'symptom.nose_discharge': value['nose_discharge'],
    };

    for (final entry in categories.entries) {
      final color = _getSymptomColor(entry.key, entry.value);
      if (color == null) continue;

      final label = entry.key.tr();
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      );
    }

    return items;
  }

  Widget _buildDetails(BuildContext context, Map<String, dynamic> value) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    void addRow(String label, dynamic val) {
      if (val == null) return;
      String display;
      if (val is bool) {
        display = val ? 'Yes' : 'No';
      } else {
        display = 'symptom.$val'.tr();
        if (display == 'symptom.$val') display = val.toString();
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const Spacer(),
              Text(
                display,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    addRow('symptom.appetite'.tr(), value['appetite']);
    addRow('symptom.energy'.tr(), value['energy']);
    addRow('symptom.vomiting'.tr(), value['vomiting']);
    addRow('symptom.diarrhea'.tr(), value['diarrhea']);
    addRow('symptom.coughing'.tr(), value['coughing']);
    addRow('symptom.skin_condition'.tr(), value['skin_condition']);
    addRow('symptom.eye_discharge'.tr(), value['eye_discharge']);
    addRow('symptom.nose_discharge'.tr(), value['nose_discharge']);

    // Custom symptoms
    final customSymptoms = value['custom_symptoms'] as List<dynamic>?;
    if (customSymptoms != null && customSymptoms.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            children: customSymptoms.map((s) {
              return Chip(
                label: Text(s.toString()),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Color? _getSymptomColor(String key, dynamic value) {
    if (value == null) return null;

    // Boolean symptoms
    if (value is bool) {
      return value ? const Color(0xFFEF5350) : const Color(0xFF66BB6A);
    }

    // Level-based symptoms
    final strValue = value.toString().toLowerCase();
    switch (strValue) {
      case 'good':
      case 'active':
      case 'normal':
      case 'none':
        return const Color(0xFF66BB6A);
      case 'poor':
      case 'lethargic':
      case 'severe':
      case 'rash':
      case 'itchy':
        return const Color(0xFFEF5350);
      case 'mild':
      case 'dry':
        return const Color(0xFFFFCA28);
      default:
        return Colors.grey;
    }
  }

  Color _getOverallStatusColor(Map<String, dynamic> value) {
    int concernCount = 0;

    // Check boolean symptoms
    if (value['vomiting'] == true) concernCount++;
    if (value['diarrhea'] == true) concernCount++;
    if (value['coughing'] == true) concernCount++;

    // Check level-based symptoms
    final levels = [
      value['appetite'],
      value['energy'],
      value['skin_condition'],
      value['eye_discharge'],
      value['nose_discharge'],
    ];

    for (final level in levels) {
      if (level == null) continue;
      final str = level.toString().toLowerCase();
      if (str == 'poor' || str == 'lethargic' || str == 'severe' ||
          str == 'rash' || str == 'itchy') {
        concernCount++;
      } else if (str == 'mild' || str == 'dry') {
        concernCount++;
      }
    }

    if (concernCount >= 3) return const Color(0xFFEF5350);
    if (concernCount >= 1) return const Color(0xFFFFCA28);
    return const Color(0xFF66BB6A);
  }
}
