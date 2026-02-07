import 'package:flutter/material.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/ui/theme/app_colors.dart';
import 'package:petcare/utils/record_utils.dart';

class Time24Table extends StatelessWidget {
  const Time24Table({super.key, required this.records, required this.onRecordTap});

  final List<Record> records;
  final Function(Record) onRecordTap;

  @override
  Widget build(BuildContext context) {
    final Color outline = Theme.of(context).colorScheme.outlineVariant;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color onSurfaceVariant = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
      ),
      child: Column(
        children: List.generate(24, (i) {
          final recordsForHour = records.where((r) => r.at.hour == i).toList();
          final String label = _labelForRow(i);
          final BorderSide bottomLine = i == 23
              ? BorderSide.none
              : BorderSide(color: outline);
          return SizedBox(
            height: 32, // 행 높이를 32로 변경
            child: Row(
              children: [
                // Left time label cell
                Container(
                  width: 45, // 시간 라벨 영역의 고정 너비를 45px로 줄임
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.3),
                    border: Border(
                      right: BorderSide(color: outline),
                      bottom: bottomLine,
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Right content cell
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: bottomLine),
                    ),
                    child: recordsForHour.isEmpty
                        ? null
                        : Row(
                            children: recordsForHour.map((record) {
                              return _buildRecordButton(
                                context,
                                record,
                                recordsForHour.length,
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordButton(
    BuildContext context,
    Record record,
    int totalRecords,
  ) {
    final typeColor = AppColors.getRecordTypeColor(record.type);

    // 총 기록 개수에 따라 버튼 크기 조정 (1개면 전체 너비, 2개면 각각 50%, 3개면 각각 33% 등)
    final double flexValue = 1.0 / totalRecords;

    return Expanded(
      flex: (flexValue * 100).round(), // flex는 정수여야 하므로 100을 곱해서 반올림
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: InkWell(
          onTap: () => onRecordTap(record),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ), // 타임라인 행 높이 32px에 맞춰 패딩 조정
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: typeColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(RecordUtils.getIconForAnyType(record.type), size: 18, color: typeColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${RecordUtils.getLabelForType(context, record.type)}${record.content != null && record.content!.isNotEmpty ? ': ${record.content}' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelForRow(int index) {
    if (index == 0) return '12';
    if (index == 23) return '23';
    final int hour = index;
    return hour.toString();
  }
}
