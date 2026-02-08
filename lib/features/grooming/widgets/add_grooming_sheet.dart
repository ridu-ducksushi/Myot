import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/grooming_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/core/providers/reminders_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/data/models/reminder.dart';

class AddGroomingSheet extends ConsumerStatefulWidget {
  const AddGroomingSheet({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<AddGroomingSheet> createState() => _AddGroomingSheetState();
}

class _AddGroomingSheetState extends ConsumerState<AddGroomingSheet> {
  final _noteController = TextEditingController();
  String _selectedSubType = 'bath';
  DateTime _selectedDate = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.0,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'grooming.add_new'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Form fields
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // SubType Selection
                      Text(
                        'grooming.select_type'.tr(),
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: groomingSubTypes.map((subType) {
                          final isSelected = _selectedSubType == subType;
                          return ChoiceChip(
                            label: Text(_subTypeDisplayName(subType)),
                            avatar: Icon(
                              _subTypeIcon(subType),
                              size: 18,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            selected: isSelected,
                            selectedColor: colorScheme.primaryContainer,
                            onSelected: (_) {
                              setState(() {
                                _selectedSubType = subType;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Date picker
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text('grooming.date'.tr()),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(_selectedDate),
                        ),
                        onTap: _selectDate,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Next due date picker (optional)
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: Text('grooming.next_due_date'.tr()),
                        subtitle: Text(
                          _nextDueDate != null
                              ? DateFormat('yyyy-MM-dd')
                                  .format(_nextDueDate!)
                              : 'grooming.not_set'.tr(),
                        ),
                        trailing: _nextDueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _nextDueDate = null);
                                },
                              )
                            : null,
                        onTap: _selectNextDueDate,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'grooming.notes'.tr(),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                // Buttons
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('common.cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text('common.save'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectNextDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _nextDueDate = date;
      });
    }
  }

  Future<void> _save() async {
    final now = DateTime.now();

    // Build value map
    final value = <String, dynamic>{
      'subType': _selectedSubType,
    };
    if (_nextDueDate != null) {
      value['nextDueDate'] = _nextDueDate!.toIso8601String();
    }

    final record = Record(
      id: now.millisecondsSinceEpoch.toString(),
      petId: widget.petId,
      type: 'grooming',
      title: _subTypeDisplayName(_selectedSubType),
      content: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      value: value,
      at: _selectedDate,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(recordsProvider.notifier).addRecord(record);

    // Create a reminder if nextDueDate is set
    if (_nextDueDate != null) {
      final reminder = Reminder(
        id: '${now.millisecondsSinceEpoch}_reminder',
        petId: widget.petId,
        type: 'grooming',
        title: '${'grooming.reminder_prefix'.tr()} ${_subTypeDisplayName(_selectedSubType)}',
        note: 'grooming.auto_reminder_note'.tr(),
        scheduledAt: _nextDueDate!,
        createdAt: now,
      );
      await ref.read(remindersProvider.notifier).addReminder(reminder);
    }

    if (mounted) {
      Navigator.of(context).pop();
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
