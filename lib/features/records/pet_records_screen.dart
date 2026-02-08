import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/ui/theme/app_colors.dart';
import 'package:petcare/ui/widgets/app_record_calendar.dart';
import 'package:petcare/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:petcare/features/records/records_chart_screen.dart';
import 'package:petcare/utils/record_utils.dart';
import 'package:petcare/features/records/widgets/time_24_table.dart';
import 'package:petcare/features/records/widgets/record_card.dart';
import 'package:petcare/features/records/widgets/poop_detail_sheet.dart';
import 'package:petcare/features/records/widgets/urine_detail_sheet.dart';
import 'package:petcare/features/records/widgets/water_intake_sheet.dart';
import 'package:petcare/features/records/widgets/walk_record_sheet.dart';
import 'package:petcare/features/records/widgets/symptom_checklist_sheet.dart';

class _RecordCategoryAction {
  const _RecordCategoryAction({required this.icon, required this.type});

  final IconData icon;
  final String type;
}

const Map<String, List<_RecordCategoryAction>> _recordCategoryActions = {
  'food': [
    _RecordCategoryAction(icon: Icons.dinner_dining, type: 'food_meal'),
    _RecordCategoryAction(icon: Icons.cookie, type: 'food_snack'),
    _RecordCategoryAction(icon: Icons.water_drop, type: 'food_water'),
    _RecordCategoryAction(icon: Icons.medical_services, type: 'food_med'),
    _RecordCategoryAction(icon: Icons.medication, type: 'food_supplement'),
  ],
  'activity': [
    _RecordCategoryAction(icon: Icons.gamepad_outlined, type: 'activity_play'),
    _RecordCategoryAction(
      icon: Icons.explore_outlined,
      type: 'activity_explore',
    ),
    _RecordCategoryAction(icon: Icons.directions_walk, type: 'activity_walk'),
    _RecordCategoryAction(icon: Icons.directions_walk, type: 'activity_outing'),
    _RecordCategoryAction(icon: Icons.hotel_outlined, type: 'activity_rest'),
    _RecordCategoryAction(icon: Icons.more_horiz, type: 'activity_other'),
  ],
  'health': [
    _RecordCategoryAction(icon: Icons.vaccines, type: 'health_vaccine'),
    _RecordCategoryAction(icon: Icons.local_hospital, type: 'health_visit'),
    _RecordCategoryAction(icon: Icons.medical_information, type: 'health_symptom'),
    _RecordCategoryAction(icon: Icons.more_horiz, type: 'health_weight'),
  ],
  'poop': [
    _RecordCategoryAction(icon: Icons.opacity, type: 'poop_urine'),
    _RecordCategoryAction(icon: Icons.pets, type: 'poop_feces'),
    _RecordCategoryAction(icon: Icons.brush, type: 'hygiene_brush'),
    _RecordCategoryAction(icon: Icons.more_horiz, type: 'poop_other'),
  ],
};

class PetRecordsScreen extends ConsumerStatefulWidget {
  const PetRecordsScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetRecordsScreen> createState() => _PetRecordsScreenState();
}

class _PetRecordsScreenState extends ConsumerState<PetRecordsScreen> {
  bool _isFoodMenuVisible = false;
  bool _isActivityMenuVisible = false;
  bool _isPoopMenuVisible = false;
  bool _isHealthMenuVisible = false;
  DateTime _selectedDate = DateTime.now();

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    // Load records for this specific pet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordsProvider.notifier).loadRecords(widget.petId);
    });
  }

  Future<void> _saveSelectedDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await prefs.setString('records_selected_date_${widget.petId}', iso);
    } catch (e) {
      debugPrint('Failed to save selected date: $e');
    }
  }

  Future<void> _showRecordCalendar(
    BuildContext context,
    List<Record> allRecords,
  ) async {
    final recordDates = allRecords
        .map((record) => _dateOnly(record.at))
        .toSet();

    final pickedDate = await showRecordCalendarDialog(
      context: context,
      initialDate: _selectedDate,
      markedDates: recordDates,
      lastDay: DateTime.now(),
    );

    if (pickedDate != null && !isSameDay(pickedDate, _selectedDate)) {
      setState(() => _selectedDate = pickedDate);
      _saveSelectedDate(_selectedDate);
    }
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySubMenu(
    BuildContext context,
    Pet pet,
    String categoryKey,
  ) {
    final actions =
        _recordCategoryActions[categoryKey] ?? const <_RecordCategoryAction>[];
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    final background = AppColors.getRecordCategorySoftColor(categoryKey);
    final color = AppColors.getRecordCategoryDarkColor(categoryKey);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            _buildSubMenuItem(
              icon: actions[i].icon,
              label: RecordUtils.getLabelForType(context, actions[i].type),
              onTap: () => _addRecord(context, pet, actions[i].type),
              color: color,
            ),
            if (i != actions.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required Pet pet,
    required bool isMenuVisible,
    required VoidCallback onToggle,
    required String categoryKey,
    required IconData fabIcon,
    required String heroTag,
    required String tooltipKey,
  }) {
    final background = AppColors.getRecordCategorySoftColor(categoryKey);
    final foreground = AppColors.getRecordCategoryDarkColor(categoryKey);
    final categoryLabel = tr('records.category.$categoryKey', context: context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isMenuVisible) _buildCategorySubMenu(context, pet, categoryKey),
        if (isMenuVisible) const SizedBox(width: AppConstants.mediumSpacing),
        FloatingActionButton(
          heroTag: heroTag,
          tooltip: tr(tooltipKey, context: context),
          backgroundColor: background,
          foregroundColor: foreground,
          onPressed: onToggle,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fabIcon, size: 20),
              const SizedBox(height: 2),
              Text(
                categoryLabel,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    // 선택된 날짜에 해당하는 레코드만 필터링
    final List<Record> allRecords = ref.watch(
      recordsForPetProvider(widget.petId),
    );
    final List<Record> records = allRecords.where((record) {
      final recordDate = record.at;
      return recordDate.year == _selectedDate.year &&
          recordDate.month == _selectedDate.month &&
          recordDate.day == _selectedDate.day;
    }).toList();

    if (pet == null) {
      return Scaffold(
        body: SafeArea(
          child: AppEmptyState(
            icon: Icons.pets,
            title: 'pets.not_found'.tr(),
            message: 'pets.not_found_message'.tr(),
          ),
        ),
      );
    }

    Widget recordsView = Time24Table(
      records: records,
      onRecordTap: (record) => _showRecordEditDialog(context, record, pet),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.mediumSpacing),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.mediumSpacing),
              // 날짜 선택 헤더 with 네비게이션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 이전 날짜 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(
                            const Duration(days: 1),
                          );
                        });
                        _saveSelectedDate(_selectedDate);
                      },
                      child: SizedBox(
                        width: AppConstants.recordsNavButtonWidth,
                        height: AppConstants.recordsNavButtonHeight,
                        child: Center(
                          child: Icon(
                            Icons.chevron_left,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 날짜 표시 및 선택 + 차트 아이콘 (중앙 정렬)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showRecordCalendar(context, allRecords),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.smallSpacing,
                            vertical: AppConstants.xSmallSpacing,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(_selectedDate),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.mediumSpacing),
                      // 차트 아이콘 (Health 화면과 동일한 스타일)
                      InkWell(
                        onTap: () {
                          context.go(
                            '/pets/${widget.petId}/records-chart?name=${Uri.encodeComponent(pet.name)}',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppConstants.smallSpacing,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.bar_chart,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 다음 날짜 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final tomorrow = _selectedDate.add(
                          const Duration(days: 1),
                        );
                        if (tomorrow.isBefore(
                          DateTime.now().add(const Duration(days: 1)),
                        )) {
                          setState(() {
                            _selectedDate = tomorrow;
                          });
                          _saveSelectedDate(_selectedDate);
                        }
                      },
                      child: SizedBox(
                        width: AppConstants.recordsNavButtonWidth,
                        height: AppConstants.recordsNavButtonHeight,
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.mediumSpacing),
              Expanded(child: SingleChildScrollView(child: recordsView)),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCategorySection(
            context: context,
            pet: pet,
            isMenuVisible: _isFoodMenuVisible,
            onToggle: () {
              setState(() {
                _isFoodMenuVisible = !_isFoodMenuVisible;
                _isActivityMenuVisible = false;
                _isPoopMenuVisible = false;
                _isHealthMenuVisible = false;
              });
            },
            categoryKey: 'food',
            fabIcon: Icons.restaurant,
            heroTag: 'record-food',
            tooltipKey: 'records.type.food',
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildCategorySection(
            context: context,
            pet: pet,
            isMenuVisible: _isActivityMenuVisible,
            onToggle: () {
              setState(() {
                _isActivityMenuVisible = !_isActivityMenuVisible;
                _isFoodMenuVisible = false;
                _isPoopMenuVisible = false;
                _isHealthMenuVisible = false;
              });
            },
            categoryKey: 'activity',
            fabIcon: Icons.sports_tennis,
            heroTag: 'record-play',
            tooltipKey: 'records.type.play',
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildCategorySection(
            context: context,
            pet: pet,
            isMenuVisible: _isPoopMenuVisible,
            onToggle: () {
              setState(() {
                _isPoopMenuVisible = !_isPoopMenuVisible;
                _isFoodMenuVisible = false;
                _isActivityMenuVisible = false;
                _isHealthMenuVisible = false;
              });
            },
            categoryKey: 'poop',
            fabIcon: Icons.cleaning_services,
            heroTag: 'record-poop',
            tooltipKey: 'records.type.poop',
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          _buildCategorySection(
            context: context,
            pet: pet,
            isMenuVisible: _isHealthMenuVisible,
            onToggle: () {
              setState(() {
                _isHealthMenuVisible = !_isHealthMenuVisible;
                _isFoodMenuVisible = false;
                _isActivityMenuVisible = false;
                _isPoopMenuVisible = false;
              });
            },
            categoryKey: 'health',
            fabIcon: Icons.favorite,
            heroTag: 'record-health',
            tooltipKey: 'records.type.health',
          ),
        ],
      ),
    );
  }

  void _closeAllSubMenus() {
    setState(() {
      _isFoodMenuVisible = false;
      _isActivityMenuVisible = false;
      _isPoopMenuVisible = false;
      _isHealthMenuVisible = false;
    });
  }

  void _addRecord(BuildContext context, Pet pet, String type) {
    // 전문 시트가 있는 타입은 바텀시트로 처리
    if (_hasDetailSheet(type)) {
      _showDetailSheet(context, pet, type);
      return;
    }

    final TextEditingController noteController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  Icon(
                    RecordUtils.getIconForType(type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Text('records.add_new'.tr()),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'records.content'.tr(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('Time: ${selectedTime.format(context)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('common.cancel'.tr()),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _closeAllSubMenus();
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return TextButton(
                      child: Text('common.save'.tr()),
                      onPressed: () {
                        final now = DateTime.now();
                        final recordAt = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final newRecord = Record(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          petId: pet.id,
                          type: type,
                          title: type, // Using type as title for now
                          content: noteController.text,
                          at: recordAt,
                          createdAt: now,
                          updatedAt: now,
                        );
                        ref.read(recordsProvider.notifier).addRecord(newRecord);
                        Navigator.of(context).pop();
                        _closeAllSubMenus();
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasDetailSheet(String type) {
    return const [
      'poop_feces', 'poop_urine', 'food_water',
      'activity_walk', 'health_symptom',
    ].contains(type);
  }

  void _showDetailSheet(BuildContext context, Pet pet, String type) {
    _closeAllSubMenus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        switch (type) {
          case 'poop_feces':
            return PoopDetailSheet(
              onSave: (value, note) {
                _saveRecordWithValue(pet, type, value, note);
                Navigator.of(ctx).pop();
              },
            );
          case 'poop_urine':
            return UrineDetailSheet(
              onSave: (value, note) {
                _saveRecordWithValue(pet, type, value, note);
                Navigator.of(ctx).pop();
              },
            );
          case 'food_water':
            return WaterIntakeSheet(
              onSave: (value, note) {
                _saveRecordWithValue(pet, type, value, note);
                Navigator.of(ctx).pop();
              },
            );
          case 'activity_walk':
            return WalkRecordSheet(
              onSave: (value, note) {
                _saveRecordWithValue(pet, type, value, note);
                Navigator.of(ctx).pop();
              },
            );
          case 'health_symptom':
            return SymptomChecklistSheet(
              onSave: (value, note) {
                _saveRecordWithValue(pet, type, value, note);
                Navigator.of(ctx).pop();
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  void _saveRecordWithValue(
    Pet pet, String type, Map<String, dynamic> value, String note,
  ) {
    final now = DateTime.now();
    final recordAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );
    final newRecord = Record(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      petId: pet.id,
      type: type,
      title: type,
      content: note.isNotEmpty ? note : null,
      value: value,
      at: recordAt,
      createdAt: now,
      updatedAt: now,
    );
    ref.read(recordsProvider.notifier).addRecord(newRecord);
  }

  void _showRecordEditDialog(BuildContext context, Record record, Pet pet) {
    final TextEditingController contentController = TextEditingController(
      text: record.content ?? '',
    );
    DateTime selectedDate = record.at;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(record.at);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('records.dialog.edit_title'.tr()),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 항목명 (읽기 전용)
                      Text(
                        'records.dialog.field_label'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.mediumSpacing,
                          vertical: AppConstants.mediumSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.5),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              RecordUtils.getIconForType(record.type),
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              RecordUtils.getLabelForType(context, record.type),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.largeSpacing),

                      // 날짜
                      Text(
                        'records.dialog.date'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.mediumSpacing,
                            vertical: AppConstants.mediumSpacing,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppConstants.smallSpacing),
                              Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.largeSpacing),

                      // 시간
                      Text(
                        'records.dialog.time'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.mediumSpacing,
                            vertical: AppConstants.mediumSpacing,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppConstants.smallSpacing),
                              Text(selectedTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.largeSpacing),

                      // 메모
                      Text(
                        'records.dialog.note'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallSpacing),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'records.dialog.note_hint'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.mediumSpacing,
                            vertical: AppConstants.smallSpacing,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                // 삭제 버튼
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmDialog(context, record);
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text(
                    'common.delete'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: AppConstants.largeSpacing),
                // 취소 버튼
                TextButton(
                  child: Text('common.cancel'.tr()),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _closeAllSubMenus();
                  },
                ),
                // 저장 버튼
                Consumer(
                  builder: (context, ref, child) {
                    return TextButton(
                      child: Text('common.save'.tr()),
                      onPressed: () {
                        final updatedRecord = record.copyWith(
                          content: contentController.text,
                          at: selectedDate,
                          updatedAt: DateTime.now(),
                        );
                        ref
                            .read(recordsProvider.notifier)
                            .updateRecord(updatedRecord);
                        Navigator.of(context).pop();
                        _closeAllSubMenus();
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Record record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('records.dialog.delete_title'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: Text(
              'records.dialog.delete_message'.tr(
                args: [RecordUtils.getLabelForType(context, record.type)],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('common.cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
                _closeAllSubMenus();
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return TextButton(
                  child: Text(
                    'common.delete'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    ref.read(recordsProvider.notifier).deleteRecord(record.id);
                    Navigator.of(context).pop();
                    _closeAllSubMenus();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
