import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/grooming_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/features/grooming/widgets/add_grooming_sheet.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';

class GroomingScreen extends ConsumerStatefulWidget {
  const GroomingScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<GroomingScreen> createState() => _GroomingScreenState();
}

class _GroomingScreenState extends ConsumerState<GroomingScreen> {
  String? _selectedSubType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordsProvider.notifier).loadRecords(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groomingRecords =
        ref.watch(groomingRecordsForPetProvider(widget.petId));
    final colorScheme = Theme.of(context).colorScheme;

    // Apply subType filter if selected
    final filteredRecords = _selectedSubType == null
        ? groomingRecords
        : groomingRecords.where((record) {
            final value = record.value;
            if (value == null) return false;
            return value['subType'] == _selectedSubType;
          }).toList();

    return Scaffold(
      appBar: AppCustomAppBar(
        title: Text('grooming.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGroomingSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // SubType filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'grooming.all'.tr(),
                    isSelected: _selectedSubType == null,
                    onSelected: () {
                      setState(() => _selectedSubType = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...groomingSubTypes.map((subType) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        context,
                        label: _subTypeDisplayName(subType),
                        isSelected: _selectedSubType == subType,
                        onSelected: () {
                          setState(() => _selectedSubType = subType);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Summary cards for each subType
          if (_selectedSubType == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: groomingSubTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final subType = groomingSubTypes[index];
                    return _buildSubTypeSummaryCard(
                        context, subType, colorScheme);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Records list
          Expanded(
            child: filteredRecords.isEmpty
                ? AppEmptyState(
                    icon: Icons.cleaning_services,
                    title: 'grooming.empty_title'.tr(),
                    message: 'grooming.empty_message'.tr(),
                    action: ElevatedButton.icon(
                      onPressed: () => _showAddGroomingSheet(context),
                      icon: const Icon(Icons.add),
                      label: Text('grooming.add_first'.tr()),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(recordsProvider.notifier)
                        .loadRecords(widget.petId),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        return _buildGroomingRecordCard(
                            context, filteredRecords[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGroomingSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSubTypeSummaryCard(
      BuildContext context, String subType, ColorScheme colorScheme) {
    final lastDate = ref.watch(
        lastGroomingDateProvider((petId: widget.petId, subType: subType)));
    final nextDueDate = ref.watch(
        nextGroomingDueDateProvider((petId: widget.petId, subType: subType)));
    final now = DateTime.now();
    final isOverdue = nextDueDate != null && nextDueDate.isBefore(now);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: colorScheme.error.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_subTypeIcon(subType), size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _subTypeDisplayName(subType),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastDate != null
                ? DateFormat('MM/dd').format(lastDate)
                : 'grooming.no_record'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (nextDueDate != null) ...[
            const SizedBox(height: 2),
            Text(
              isOverdue
                  ? 'grooming.overdue'.tr()
                  : 'grooming.next_due'.tr(
                      args: [DateFormat('MM/dd').format(nextDueDate)]),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverdue ? colorScheme.error : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroomingRecordCard(BuildContext context, Record record) {
    final value = record.value ?? {};
    final subType = value['subType'] as String? ?? 'other';
    final nextDueDateStr = value['nextDueDate'] as String?;
    final nextDueDate =
        nextDueDateStr != null ? DateTime.tryParse(nextDueDateStr) : null;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _subTypeIcon(subType),
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _subTypeDisplayName(subType),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(record.at),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (nextDueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'grooming.next_due_label'.tr(
                          args: [DateFormat('yyyy-MM-dd').format(nextDueDate)]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                  if (record.content != null &&
                      record.content!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      record.content!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: colorScheme.onSurfaceVariant),
              onPressed: () => _confirmDelete(context, record.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGroomingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => AddGroomingSheet(petId: widget.petId),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('grooming.delete_title'.tr()),
        content: Text('grooming.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(recordsProvider.notifier).deleteRecord(recordId);
    }
  }

  String _subTypeDisplayName(String subType) {
    switch (subType) {
      case 'bath':
        return 'grooming.bath'.tr();
      case 'nail_trim':
        return 'grooming.nail_trim'.tr();
      case 'ear_clean':
        return 'grooming.ear_clean'.tr();
      case 'teeth_brush':
        return 'grooming.teeth_brush'.tr();
      case 'haircut':
        return 'grooming.haircut'.tr();
      default:
        return subType;
    }
  }

  IconData _subTypeIcon(String subType) {
    switch (subType) {
      case 'bath':
        return Icons.bathtub;
      case 'nail_trim':
        return Icons.content_cut;
      case 'ear_clean':
        return Icons.hearing;
      case 'teeth_brush':
        return Icons.brush;
      case 'haircut':
        return Icons.cut;
      default:
        return Icons.cleaning_services;
    }
  }
}
