import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/pet_supplies.dart';
import 'package:petcare/data/repositories/pet_supplies_repository.dart';
import 'package:petcare/features/labs/weight_chart_screen.dart';
import 'package:petcare/features/pets/models/pet_tool.dart';
import 'package:petcare/features/pets/widgets/daily_supplies_section.dart';
import 'package:petcare/features/pets/widgets/edit_pet_sheet.dart';
import 'package:petcare/features/pets/widgets/edit_supplies_sheet.dart';
import 'package:petcare/features/pets/widgets/profile_header_card.dart';
import 'package:petcare/features/pets/widgets/profile_memo_field.dart';
import 'package:petcare/features/pets/widgets/tools_grid_section.dart';
import 'package:petcare/ui/theme/app_gradients.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/utils/app_logger.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  late DateTime _currentSuppliesDate;
  Set<DateTime> _suppliesRecordDates = {};
  PetSupplies? _currentSupplies;
  bool _isInitialized = false;
  late PetSuppliesRepository _suppliesRepository;

  void _initialize(Pet pet) {
    if (_isInitialized) return;
    _suppliesRepository = PetSuppliesRepository(
      supabase: Supabase.instance.client,
      localDb: LocalDatabase.instance,
    );
    _currentSuppliesDate = DateTime.now();
    _loadSelectedDate(pet.id);
    _loadSuppliesRecordDates();
    _loadCurrentSupplies();
    _isInitialized = true;
  }

  Future<void> _loadSelectedDate(String petId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString('selected_date_$petId');
      if (iso != null && iso.isNotEmpty) {
        final parts = iso.split('-');
        if (parts.length == 3) {
          _currentSuppliesDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSelectedDate(String petId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await prefs.setString('selected_date_$petId', iso);
    } catch (_) {}
  }

  Future<void> _loadSuppliesRecordDates() async {
    try {
      final dates = await _suppliesRepository.getSuppliesRecordDates(widget.petId);
      if (mounted) {
        setState(() {
          _suppliesRecordDates = dates.toSet();
        });
      }
    } catch (e) {
      AppLogger.e('PetDetail', 'Error loading supplies record dates', e);
    }
  }

  Future<void> _loadCurrentSupplies() async {
    try {
      final supplies = await _suppliesRepository.getSuppliesByDate(
        widget.petId,
        _currentSuppliesDate,
      );
      if (mounted) {
        setState(() {
          _currentSupplies = supplies;
        });
      }
    } catch (e) {
      AppLogger.e('PetDetail', 'Error loading current supplies', e);
    }
  }

  Future<void> _updatePet(Pet updated, {String? successKey, String? errorKey}) async {
    try {
      await ref.read(petsProvider.notifier).updatePet(updated);
      if (mounted && successKey != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successKey.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted && errorKey != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorKey.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _onImageSelected(Pet pet, String imagePath) {
    return _updatePet(
      pet.copyWith(
        avatarUrl: imagePath,
        defaultIcon: null,
        profileBgColor: null,
        updatedAt: DateTime.now(),
      ),
      successKey: 'pets.image_updated',
      errorKey: 'pets.image_update_error',
    );
  }

  Future<void> _onImageCleared(Pet pet) {
    return _updatePet(
      pet.copyWith(
        avatarUrl: null,
        defaultIcon: null,
        profileBgColor: null,
        updatedAt: DateTime.now(),
      ),
      successKey: 'pets.image_deleted',
      errorKey: 'pets.image_delete_error',
    );
  }

  Future<void> _onDefaultIconSelected(Pet pet, String iconName, String bgColor) {
    return _updatePet(
      pet.copyWith(
        defaultIcon: iconName,
        profileBgColor: bgColor,
        avatarUrl: null,
        updatedAt: DateTime.now(),
      ),
      successKey: 'pets.profile_set_success',
      errorKey: 'pets.profile_set_error',
    );
  }

  void _editPet(Pet pet, {String? focusField}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPetSheet(
        pet: pet,
        initialFocusField: focusField,
      ),
    );
  }

  void _editSupplies(Pet pet, {String? focusField}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditSuppliesSheet(
        pet: pet,
        selectedDate: _currentSuppliesDate,
        existingSupplies: _currentSupplies,
        initialFocusField: focusField,
        onSaved: (savedSupplies, dates) {
          setState(() {
            _currentSupplies = savedSupplies;
            _currentSuppliesDate = savedSupplies.recordedAt;
            _suppliesRecordDates = dates.toSet();
          });
        },
      ),
    );
  }

  void _showWeightChart(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeightChartScreen(
          petId: pet.id,
          petName: pet.name,
        ),
      ),
    );
  }

  void _onToolSelected(Pet pet, PetTool tool) {
    context.go(tool.route(pet.id));
  }

  void _moveToPreviousSuppliesRecord(Pet pet) {
    final previousDates = _suppliesRecordDates
        .where((date) => date.isBefore(_currentSuppliesDate))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (previousDates.isNotEmpty) {
      setState(() {
        _currentSuppliesDate = previousDates.first;
      });
      _saveSelectedDate(pet.id, _currentSuppliesDate);
      _loadCurrentSupplies();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('supplies.no_previous'.tr())),
      );
    }
  }

  void _moveToNextSuppliesRecord(Pet pet) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDates = _suppliesRecordDates
        .where((date) => date.isAfter(_currentSuppliesDate))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (nextDates.isNotEmpty) {
      setState(() {
        _currentSuppliesDate = nextDates.first;
      });
      _saveSelectedDate(pet.id, _currentSuppliesDate);
      _loadCurrentSupplies();
    } else if (!isSameDay(_currentSuppliesDate, today)) {
      setState(() {
        _currentSuppliesDate = today;
      });
      _saveSelectedDate(pet.id, _currentSuppliesDate);
      _loadCurrentSupplies();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('supplies.latest_record'.tr())),
      );
    }
  }

  Future<void> _showSuppliesCalendarDialog(Pet pet) async {
    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'common.select_date'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TableCalendar<dynamic>(
                firstDay: DateTime(2000),
                lastDay: DateTime.now(),
                focusedDay: _currentSuppliesDate,
                selectedDayPredicate: (day) =>
                    isSameDay(_currentSuppliesDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _currentSuppliesDate = selectedDay;
                  });
                  _saveSelectedDate(pet.id, _currentSuppliesDate);
                  _loadCurrentSupplies();
                  Navigator.of(context).pop();
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders<dynamic>(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_suppliesRecordDates
                        .any((date) => isSameDay(date, day))) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(color: cs.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('common.close'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: Text('pets.not_found'.tr())),
        body: AppEmptyState(
          icon: Icons.pets,
          title: 'pets.not_found'.tr(),
          message: 'pets.not_found_message'.tr(),
        ),
      );
    }

    _initialize(pet);

    final cs = Theme.of(context).colorScheme;

    final mediaTopInset = MediaQuery.of(context).padding.top;
    final mediaBottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('pets.profile'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: mediaBottomInset + 100),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppGradients.softBackground(cs),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: mediaTopInset + kToolbarHeight + 8,
                  bottom: 8,
                ),
                child: ProfileHeaderCard(
                  pet: pet,
                  onEditField: (field) => _editPet(pet, focusField: field),
                  onShowWeightChart: () => _showWeightChart(pet),
                  onImageSelected: (path) => _onImageSelected(pet, path),
                  onImageCleared: () => _onImageCleared(pet),
                  onDefaultIconSelected: (icon, bg) =>
                      _onDefaultIconSelected(pet, icon, bg),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ProfileMemoField(
                memo: pet.note,
                onTap: () => _editPet(pet, focusField: 'note'),
              ),
            ),
            ToolsGridSection(
              petId: pet.id,
              onSelected: (tool) => _onToolSelected(pet, tool),
            ),
            DailySuppliesSection(
              currentDate: _currentSuppliesDate,
              currentSupplies: _currentSupplies,
              onPreviousDate: () => _moveToPreviousSuppliesRecord(pet),
              onNextDate: () => _moveToNextSuppliesRecord(pet),
              onPickDate: () => _showSuppliesCalendarDialog(pet),
              onEditSupply: (field) => _editSupplies(pet, focusField: field),
            ),
          ],
        ),
      ),
    );
  }
}
