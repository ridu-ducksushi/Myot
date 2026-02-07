import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/utils/app_logger.dart';

class EditPetSheet extends ConsumerStatefulWidget {
  const EditPetSheet({
    super.key,
    required this.pet,
    this.initialFocusField,
  });

  final Pet pet;
  final String? initialFocusField;

  @override
  ConsumerState<EditPetSheet> createState() => EditPetSheetState();
}

class EditPetSheetState extends ConsumerState<EditPetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _speciesFocusNode = FocusNode();
  final FocusNode _breedFocusNode = FocusNode();
  final FocusNode _sexFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  final FocusNode _birthDateFocusNode = FocusNode();
  final GlobalKey _birthDateTileKey = GlobalKey();
  final TextEditingController _customSpeciesController = TextEditingController(); // Other 선택 시 종 입력용

  String _selectedSpecies = 'Dog';
  String? _selectedSex;
  bool? _isNeutered;
  DateTime? _birthDate;

  final List<String> _species = [
    'Dog', 'Cat', 'Other'
  ];

  List<String> get _sexOptions => ['settings.sex_male'.tr(), 'settings.sex_female'.tr()];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = widget.initialFocusField;
      debugPrint('🧭 EditPet initial focus target: $target');
      if (target == 'birthDate') {
        _birthDateFocusNode.requestFocus();
        _selectBirthDate(auto: true);
        Future.microtask(() {
          final context = _birthDateTileKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
        return;
      }
      switch (target) {
        case 'species':
          _speciesFocusNode.requestFocus();
          break;
        case 'breed':
          _breedFocusNode.requestFocus();
          break;
        case 'weight':
          _weightFocusNode.requestFocus();
          break;
        case 'note':
          _noteFocusNode.requestFocus();
          break;
        case 'sex':
          _sexFocusNode.requestFocus();
          break;
        default:
          _nameFocusNode.requestFocus();
      }
    });
  }

  void _initializeForm() {
    final pet = widget.pet;
    _nameController.text = pet.name;
    _breedController.text = pet.breed ?? '';
    _weightController.text = pet.weightKg?.toString() ?? '';
    _noteController.text = pet.note ?? '';

    // 기존 펫의 species가 표준 종류(Dog, Cat, Other)가 아니면 커스텀 종으로 간주
    if (_species.contains(pet.species)) {
      _selectedSpecies = pet.species;
    } else {
      // 커스텀 종인 경우 Other로 설정하고 커스텀 종 필드에 값 설정
      _selectedSpecies = 'Other';
      _customSpeciesController.text = pet.species;
    }
    // Male/Female을 표시용 텍스트로 변환
    _selectedSex = pet.sex == 'Male' ? 'settings.sex_male'.tr() : (pet.sex == 'Female' ? 'settings.sex_female'.tr() : pet.sex);
    _isNeutered = pet.neutered;
    _birthDate = pet.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    _customSpeciesController.dispose();
    _nameFocusNode.dispose();
    _speciesFocusNode.dispose();
    _breedFocusNode.dispose();
    _sexFocusNode.dispose();
    _weightFocusNode.dispose();
    _noteFocusNode.dispose();
    _birthDateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'pets.edit_title'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 8),
                      children: [
                        // 종류 필드
                        DropdownButtonFormField<String>(
                          value: _selectedSpecies,
                          focusNode: _speciesFocusNode,
                          decoration: InputDecoration(
                            labelText: 'pets.species'.tr(),
                            prefixIcon: const Icon(Icons.category),
                          ),
                          items: _species
                              .map(
                                (species) => DropdownMenuItem<String>(
                              value: species,
                              child: Text(species),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedSpecies = value;
                              // Other가 아닌 종류로 변경 시 커스텀 종 입력 필드 초기화
                              if (value != 'Other') {
                                _customSpeciesController.clear();
                              }
                            });
                            // Other 선택 시 커스텀 종 필드로 포커스 이동, 그 외에는 품종 필드로
                            if (value == 'Other') {
                              // 커스텀 종 필드는 아래에 추가되므로 포커스는 그대로 유지
                            } else {
                              FocusScope.of(context).requestFocus(_breedFocusNode);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Other 선택 시 종을 직접 입력할 수 있는 필드
                        if (_selectedSpecies == 'Other') ...[
                          AppTextField(
                            controller: _customSpeciesController,
                            labelText: 'pets.custom_species_label'.tr(),
                            prefixIcon: const Icon(Icons.pets),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'pets.breed_required_for_other'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 품종 필드
                        AppTextField(
                          controller: _breedController,
                          labelText: 'pets.breed'.tr(),
                          prefixIcon: const Icon(Icons.info_outline),
                          focusNode: _breedFocusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_nameFocusNode),
                        ),
                        const SizedBox(height: 16),

                        // 이름 필드
                        AppTextField(
                          controller: _nameController,
                          labelText: 'pets.name'.tr(),
                          prefixIcon: const Icon(Icons.pets),
                          focusNode: _nameFocusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_weightFocusNode),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'pets.name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 성별 필드
                        DropdownButtonFormField<String>(
                          value: _selectedSex,
                          decoration: InputDecoration(
                            labelText: 'pets.sex'.tr(),
                            prefixIcon: const Icon(Icons.wc),
                          ),
                          focusNode: _sexFocusNode,
                          items: _sexOptions.map((sex) {
                            return DropdownMenuItem(
                              value: sex,
                              child: Text(sex),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSex = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        CheckboxListTile(
                          title: Text('pets.neutered'.tr()),
                          subtitle: Text('pets.neutered_description'.tr()),
                          value: _isNeutered ?? false,
                          onChanged: (value) {
                            setState(() {
                              _isNeutered = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _weightController,
                          labelText: 'pets.weight_kg'.tr(),
                          prefixIcon: const Icon(Icons.monitor_weight),
                          keyboardType: TextInputType.number,
                          focusNode: _weightFocusNode,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          validator: (value) {
                            if (value?.isNotEmpty == true) {
                              final weight = double.tryParse(value!);
                              if (weight == null || weight <= 0) {
                                return 'pets.weight_invalid'.tr();
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        Focus(
                          focusNode: _birthDateFocusNode,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _selectBirthDate(),
                            child: ListTile(
                              key: _birthDateTileKey,
                          leading: const Icon(Icons.cake),
                          title: Text('pets.birth_date'.tr()),
                          subtitle: Text(
                            _birthDate != null
                                ? DateFormat.yMMMd().format(_birthDate!)
                                : 'pets.select_birth_date'.tr(),
                          ),
                          contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _noteController,
                          labelText: 'pets.notes'.tr(),
                          prefixIcon: const Icon(Icons.note),
                          maxLines: 3,
                          focusNode: _noteFocusNode,
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  const SizedBox(height: 40),
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
                          onPressed: _updatePet,
                          child: Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectBirthDate({bool auto = false}) async {
    if (!auto) {
      FocusScope.of(context).requestFocus(_birthDateFocusNode);
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      lastDate: DateTime.now(),
    );

    if (!mounted) return;

    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }

    if (auto) {
      FocusScope.of(context).requestFocus(_birthDateFocusNode);
    } else {
      _birthDateFocusNode.unfocus();
      FocusScope.of(context).requestFocus(_noteFocusNode);
    }
  }

  Future<void> _updatePet() async {
    if (_formKey.currentState?.validate() != true) return;

    // 표시용 텍스트를 Male/Female로 변환 (DB 저장용)
    String? sexForDb = _selectedSex;
    if (_selectedSex == 'settings.sex_male'.tr()) sexForDb = 'Male';
    if (_selectedSex == 'settings.sex_female'.tr()) sexForDb = 'Female';

    final breedValue = _breedController.text.trim();
    AppLogger.d('PetDetail', '품종 저장 디버그: 원본="${_breedController.text}", trim="${breedValue}", isEmpty=${breedValue.isEmpty}');

    // Other 선택 시 커스텀 종을 사용, 그 외에는 선택한 종류 사용
    final species = _selectedSpecies == 'Other'
        ? _customSpeciesController.text.trim()
        : _selectedSpecies;

    final updatedPet = widget.pet.copyWith(
      name: _nameController.text.trim(),
      species: species,
      breed: breedValue.isEmpty ? null : breedValue,
      sex: sexForDb,
      neutered: _isNeutered,
      birthDate: _birthDate,
      weightKg: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(petsProvider.notifier).updatePet(updatedPet);

      // Update weight in health tab's basic info if weight was changed
      if (updatedPet.weightKg != null && updatedPet.weightKg != widget.pet.weightKg) {
        try {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null) {
            final today = DateTime.now();
            final dateKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

            // Get current lab data for today
            final currentRes = await Supabase.instance.client
                .from('labs')
                .select('items')
                .eq('user_id', uid)
                .eq('pet_id', widget.pet.id)
                .eq('date', dateKey)
                .eq('panel', 'BloodTest')
                .maybeSingle();

            Map<String, dynamic> currentItems = {};
            if (currentRes != null) {
              currentItems = Map<String, dynamic>.from(currentRes['items'] ?? {});
            }

            // Update weight in lab data
            currentItems['체중'] = {
              'value': updatedPet.weightKg.toString(),
              'unit': 'kg',
              'reference': '',
            };

            // Save to Supabase
            await Supabase.instance.client
                .from('labs')
                .upsert({
                  'user_id': uid,
                  'pet_id': widget.pet.id,
                  'date': dateKey,
                  'panel': 'BloodTest',
                  'items': currentItems,
                });
          }
        } catch (e) {
          AppLogger.w('PetDetail', 'Failed to update weight in health tab: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('pets.edit_success'.tr(args: [updatedPet.name])),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('pets.edit_error'.tr(args: [widget.pet.name])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
