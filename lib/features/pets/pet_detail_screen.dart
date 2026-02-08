import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/pet_supplies.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/pet_supplies_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/ui/widgets/profile_image_picker.dart';
import 'package:petcare/features/labs/weight_chart_screen.dart';
import 'package:petcare/ui/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petcare/utils/app_logger.dart';
import 'package:petcare/features/pets/widgets/edit_pet_sheet.dart';
import 'package:petcare/features/pets/widgets/edit_supplies_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    // Repository 초기화는 build에서 수행
  }

  String _buildBirthDateDisplay(DateTime birthDate) {
    final locale = context.locale.toString();
    final dateLabel = DateFormat.yMMMd(locale).format(birthDate);
    final ageLabel = _formatAge(birthDate);
    if (ageLabel == null) {
      return dateLabel;
    }
    return '$dateLabel\n$ageLabel';
  }

  String? _formatAge(DateTime? birthDate) {
    if (birthDate == null) return null;

    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      final previousMonth = DateTime(now.year, now.month, 0);
      days += previousMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    final parts = <String>[];
    if (years > 0) {
      parts.add('pets.age_units.year'.plural(
        years,
        args: [years.toString()],
      ));
    }
    if (months > 0) {
      parts.add('pets.age_units.month'.plural(
        months,
        args: [months.toString()],
      ));
    }
    if (years <= 0 && months <= 0 && days > 0) {
      parts.add('pets.age_units.day'.plural(
        days,
        args: [days.toString()],
      ));
    }

    if (parts.isEmpty) {
      return null;
    }
    final separator = 'pets.age_units.separator'.tr();
    return parts.join(separator);
  }

  void _initialize(Pet pet) {
    if (_isInitialized) return;
    
    // Repository 초기화
    _suppliesRepository = PetSuppliesRepository(
      supabase: Supabase.instance.client,
      localDb: LocalDatabase.instance,
    );
    
    // 오늘 날짜로 초기화 후, 저장된 선택 날짜가 있으면 복원
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
      final iso = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

    // 펫 데이터가 로드되면 초기화
    _initialize(pet);

    return Scaffold(
      appBar: AppBar(
        title: Text('pets.profile'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 프로필 → 펫 카드 목록으로 일관되게 이동
            context.go('/');
          },
          ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Pet Header
            _buildPetHeader(context, pet),
            
            // Pet Supplies
            _buildPetSupplies(context, pet),
            
            const SizedBox(height: 100), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildPetHeader(BuildContext context, Pet pet) {
    final birthDateLabel = pet.birthDate != null
        ? _buildBirthDateDisplay(pet.birthDate!)
        : 'pets.select_birth_date'.tr();

    return InkWell(
      onTap: () => _editPet(context, pet, focusField: 'name'),
      borderRadius: BorderRadius.circular(0),
      child: AppCard(
        borderRadius: BorderRadius.zero,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                // 왼쪽: 프로필 이미지와 편집 아이콘 + 종족/품종
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {}, // 빈 핸들러로 상위 InkWell 이벤트 차단
                      child: ProfileImagePicker(
                imagePath: pet.avatarUrl,
                selectedDefaultIcon: pet.defaultIcon,
                    selectedBgColor: pet.profileBgColor,
                species: pet.species, // 동물 종류 전달
                onImageSelected: (image) async {
                  if (image == null) {
                    return;
                  }
                    // ProfileImagePicker에서 이미 저장된 파일을 받음
                    final updatedPet = pet.copyWith(
                      avatarUrl: image.path, // 이미 저장된 경로를 사용
                      defaultIcon: null, // 이미지 선택 시 기본 아이콘 제거
                    profileBgColor: null, // 배경색 초기화
                      updatedAt: DateTime.now(),
                    );
                    
                    try {
                      await ref.read(petsProvider.notifier).updatePet(updatedPet);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('pets.image_updated'.tr()),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('pets.image_update_error'.tr(args: [pet.name])),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                },
                onClearSelection: () async {
                    final updatedPet = pet.copyWith(
                      avatarUrl: null,
                    defaultIcon: null,
                    profileBgColor: null,
                      updatedAt: DateTime.now(),
                    );

                    try {
                      await ref.read(petsProvider.notifier).updatePet(updatedPet);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: Text('pets.image_deleted'.tr()),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: Text('pets.image_delete_error'.tr()),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                    }
                  }
                },
                    onDefaultIconSelected: (iconName, bgColor) async {
                      // 기본 아이콘과 배경색을 함께 업데이트
                  final updatedPet = pet.copyWith(
                    defaultIcon: iconName,
                        profileBgColor: bgColor,
                    avatarUrl: null, // 기본 아이콘 선택 시 이미지 제거
                    updatedAt: DateTime.now(),
                  );
                  
                  try {
                    await ref.read(petsProvider.notifier).updatePet(updatedPet);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                              content: Text('pets.profile_set_success'.tr()),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                              content: Text('pets.profile_set_error'.tr()),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                    size: 136.5,
                showEditIcon: true,
                ),
              ),
              const SizedBox(height: 8),
                    // 종족과 품종
                    Column(
                children: [
                      Transform.scale(
                        scale: 0.85,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _editPet(context, pet, focusField: 'species'),
                          child: PetSpeciesChip(species: pet.species),
                        ),
                      ),
                        // 디버그: 품종 정보 로그
                        Builder(builder: (context) {
                          AppLogger.d('PetDetail', '품종 정보: breed="${pet.breed}", isNull=${pet.breed == null}, isEmpty=${pet.breed?.isEmpty ?? true}');
                          return const SizedBox.shrink();
                        }),
                        if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Transform.scale(
                            scale: 0.85,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _editPet(context, pet, focusField: 'breed'),
                              child: Chip(
                      label: Text(pet.breed!),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                    ),
                  ],
                ],
                    ),
                ],
              ),
              
                const SizedBox(width: 12),
              
                // 오른쪽: 펫 정보들
                    Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이름
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
              ),
              
                      const SizedBox(height: 12),
              
                      // 상세 정보들
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                      child: _InfoCard(
                          icon: Icons.cake_outlined,
                          label: 'pets.birth_date'.tr(),
                          value: birthDateLabel,
                          onTap: () => _editPet(context, pet, focusField: 'birthDate'),
                      ),
                    ),
                  if (pet.weightKg != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: InkWell(
                              onTap: () => _editPet(context, pet, focusField: 'weight'),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.monitor_weight,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                    Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${pet.weightKg}kg',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                        onTap: () => _showWeightChart(context, pet),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.bar_chart,
                                              size: 18,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  if (pet.sex != null)
                        _InfoCard(
                          icon: pet.sex!.toLowerCase() == 'male' || pet.sex == '남아'
                              ? Icons.male
                              : Icons.female,
                        label: 'pets.sex'.tr(),
                          value: _getSexWithNeuteredText(pet),
                          onTap: () => _editPet(context, pet, focusField: 'sex'),
                    ),
                ],
              ),
              
                      // 메모 섹션 (기록이 없어도 영역 유지)
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _editPet(context, pet, focusField: 'note'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                  width: double.infinity,
                          padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                            pet.note ?? '',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                ),
              ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetSupplies(BuildContext context, Pet pet) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: AppCard(
        borderRadius: BorderRadius.zero,
        margin: EdgeInsets.zero,
        elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더 영역 (배경색 추가)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(minHeight: 30),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                children: [
                    // 좌측 화살표 - 이전 기록으로 이동
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _moveToPreviousSuppliesRecord(pet),
                        child: SizedBox(
                          width: 56,
                          height: 36,
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
                    Expanded(
                      child: InkWell(
                        onTap: () => _showSuppliesCalendarDialog(pet),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                  Flexible(
                    child: Text(
                                DateFormat.yMMMd(context.locale.toString()).format(_currentSuppliesDate),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 우측 화살표 - 다음 기록 또는 오늘 날짜로 이동
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _moveToNextSuppliesRecord(pet),
                        child: SizedBox(
                          width: 56,
                          height: 36,
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
              ),
              
              // 물품 목록 영역
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // 날짜별 기록 표시 안내
              if (_currentSupplies == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'supplies.no_record_for_date'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                        ),
                  ),
                ],
              ),
                ),
              InkWell(
                onTap: () => _editSupplies(context, pet, focusField: 'dryFood'),
                borderRadius: BorderRadius.circular(8),
                child: _buildSupplyItem(
                context,
                icon: Icons.restaurant,
                  label: 'supplies.dry_food'.tr(),
                  value: _currentSupplies?.dryFood,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _editSupplies(context, pet, focusField: 'wetFood'),
                borderRadius: BorderRadius.circular(8),
                child: _buildSupplyItem(
                  context,
                  icon: Icons.rice_bowl,
                  label: 'supplies.wet_food'.tr(),
                  value: _currentSupplies?.wetFood,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _editSupplies(context, pet, focusField: 'supplement'),
                borderRadius: BorderRadius.circular(8),
                child: _buildSupplyItem(
                context,
                icon: Icons.medication,
                label: 'supplies.supplement'.tr(),
                  value: _currentSupplies?.supplement,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _editSupplies(context, pet, focusField: 'snack'),
                borderRadius: BorderRadius.circular(8),
                child: _buildSupplyItem(
                context,
                icon: Icons.cookie,
                label: 'supplies.snack'.tr(),
                  value: _currentSupplies?.snack,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _editSupplies(context, pet, focusField: 'litter'),
                borderRadius: BorderRadius.circular(8),
                child: _buildSupplyItem(
                context,
                icon: Icons.cleaning_services,
                label: 'supplies.litter'.tr(),
                  value: _currentSupplies?.litter,
                ),
              ),
            ],
          ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildSupplyItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'supplies.add_placeholder'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                      color: value != null
                          ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSexWithNeuteredText(Pet pet) {
    // 성별 텍스트
    String sexText = pet.sex == 'Male' ? 'settings.sex_male'.tr() : (pet.sex == 'Female' ? 'settings.sex_female'.tr() : pet.sex ?? '');

    // 중성화 여부 텍스트
    String neuteredText = '';
    if (pet.neutered == true) {
      neuteredText = ' / ${'pets.neutered_yes'.tr()}';
    } else if (pet.neutered == false) {
      neuteredText = ' / ${'pets.neutered_no'.tr()}';
    }
    
    return sexText + neuteredText;
  }

  void _editSupplies(BuildContext context, Pet pet, {String? focusField}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditSuppliesSheet(
        pet: pet, 
        selectedDate: _currentSuppliesDate,
        existingSupplies: _currentSupplies,
        initialFocusField: focusField,
        onSaved: (savedSupplies, dates) {
          // 부모 상태 즉시 업데이트
          setState(() {
            _currentSupplies = savedSupplies;
            _currentSuppliesDate = savedSupplies.recordedAt;
            _suppliesRecordDates = dates.toSet();
          });
        },
      ),
    );
  }

  void _editPet(BuildContext context, Pet pet, {String? focusField}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPetSheet(
        pet: pet,
        initialFocusField: focusField,
      ),
    );
  }

  void _showWeightChart(BuildContext context, Pet pet) {
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

  // 이전 기록으로 이동
  void _moveToPreviousSuppliesRecord(Pet pet) {
    // 현재 날짜보다 이전 날짜 중 가장 최근 날짜 찾기
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

  // 다음 기록 또는 오늘 날짜로 이동
  void _moveToNextSuppliesRecord(Pet pet) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 현재 날짜보다 이후 날짜 중 가장 오래된 날짜 찾기
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
      // 다음 기록이 없으면 오늘로 이동
      setState(() {
        _currentSuppliesDate = today;
      });
      _saveSelectedDate(pet.id, _currentSuppliesDate);
      _loadCurrentSupplies();
    } else {
      // 이미 오늘 날짜인 경우
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('supplies.latest_record'.tr())),
      );
    }
  }

  // 달력 팝업 표시
  Future<void> _showSuppliesCalendarDialog(Pet pet) async {
    await showDialog(
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
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime.now(),
                focusedDay: _currentSuppliesDate,
                selectedDayPredicate: (day) => isSameDay(_currentSuppliesDate, day),
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
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    // 기록이 있는 날짜에 점 표시
                    if (_suppliesRecordDates.any((date) => isSameDay(date, day))) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
              value,
                textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
