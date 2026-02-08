import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/features/records/widgets/symptom_timeline_card.dart';

/// Screen that shows symptom records in a chronological timeline
/// with color-coded status indicators per symptom type.
/// Filterable by date range.
class SymptomTimelineScreen extends ConsumerStatefulWidget {
  const SymptomTimelineScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<SymptomTimelineScreen> createState() =>
      _SymptomTimelineScreenState();
}

class _SymptomTimelineScreenState
    extends ConsumerState<SymptomTimelineScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final petName = pet?.name ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    final allRecords = ref.watch(recordsForPetProvider(widget.petId));

    // Filter to symptom records within date range
    final symptomRecords = allRecords
        .where((r) => r.type == 'health_symptom' || r.type == 'symptom')
        .where((r) =>
            !r.at.isBefore(_startDate) &&
            !r.at.isAfter(_endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: Text('symptom_timeline.title'.tr(args: [petName])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Date filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${DateFormat('yyyy-MM-dd').format(_startDate)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${DateFormat('yyyy-MM-dd').format(_endDate)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline content
          Expanded(
            child: symptomRecords.isEmpty
                ? _buildEmptyState(context, colorScheme)
                : _buildTimeline(context, symptomRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'symptom_timeline.no_data'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'symptom_timeline.no_data_hint'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<Record> records) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return SymptomTimelineCard(
          record: records[index],
          isFirst: index == 0,
          isLast: index == records.length - 1,
        );
      },
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
