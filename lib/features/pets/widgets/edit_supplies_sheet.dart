import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/pet_supplies.dart';
import 'package:petcare/data/repositories/pet_supplies_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class EditSuppliesSheet extends ConsumerStatefulWidget {
  const EditSuppliesSheet({
    super.key,
    required this.pet,
    required this.selectedDate,
    this.existingSupplies,
    required this.onSaved,
    this.initialFocusField,
  });

  final Pet pet;
  final DateTime selectedDate;
  final PetSupplies? existingSupplies;
  final Function(PetSupplies, List<DateTime>) onSaved;
  final String? initialFocusField;

  @override
  ConsumerState<EditSuppliesSheet> createState() => EditSuppliesSheetState();
}

class EditSuppliesSheetState extends ConsumerState<EditSuppliesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _dryFoodController = TextEditingController();
  final _wetFoodController = TextEditingController();
  final _supplementController = TextEditingController();
  final _snackController = TextEditingController();
  final _litterController = TextEditingController();
  late final Map<String, FocusNode> _focusNodes;
  late PetSuppliesRepository _suppliesRepository;
  ScrollController? _currentScrollController;
  final Set<String> _listenersAdded = {};

  @override
  void initState() {
    super.initState();
    _focusNodes = {
      'dryFood': FocusNode(),
      'wetFood': FocusNode(),
      'supplement': FocusNode(),
      'snack': FocusNode(),
      'litter': FocusNode(),
    };
    _suppliesRepository = PetSuppliesRepository(
      Supabase.instance.client,
    );
    _initializeForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = widget.initialFocusField;
      if (target != null) {
        _focusNodes[target]?.requestFocus();
      }
    });
  }

  // 포커스 변경 시 자동 스크롤을 위한 메서드
  void _setupAutoScroll(ScrollController scrollController, String fieldKey, BuildContext context) {
    // 리스너가 이미 추가되었는지 확인
    if (_listenersAdded.contains(fieldKey)) {
      return;
    }

    _listenersAdded.add(fieldKey);
    _currentScrollController = scrollController;

    _focusNodes[fieldKey]?.addListener(() {
      if (_focusNodes[fieldKey]!.hasFocus && _currentScrollController != null) {
        // 키보드가 올라올 시간을 주기 위해 약간의 지연
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_currentScrollController!.hasClients && mounted) {
            final focusContext = _focusNodes[fieldKey]?.context;
            if (focusContext != null) {
              Scrollable.ensureVisible(
                focusContext,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.1, // 상단에서 10% 위치에 배치
              );
            }
          }
        });
      }
    });
  }

  void _initializeForm() {
    final existingSupplies = widget.existingSupplies;

    if (existingSupplies != null) {
      // 기존 기록이 있는 경우 데이터 사용
      _dryFoodController.text = existingSupplies.dryFood ?? '';
      _wetFoodController.text = existingSupplies.wetFood ?? '';
      _supplementController.text = existingSupplies.supplement ?? '';
      _snackController.text = existingSupplies.snack ?? '';
      _litterController.text = existingSupplies.litter ?? '';
    } else {
      // 새로운 기록인 경우 빈 값으로 초기화
      _dryFoodController.text = '';
      _wetFoodController.text = '';
      _supplementController.text = '';
      _snackController.text = '';
      _litterController.text = '';
    }
  }

  @override
  void dispose() {
    _dryFoodController.dispose();
    _wetFoodController.dispose();
    _supplementController.dispose();
    _snackController.dispose();
    _litterController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        maxChildSize: 0.95,
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
                    'supplies.daily_record'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  // 선택된 날짜 표시
                  Text(
                    DateFormat.yMMMd(context.locale.toString()).format(widget.selectedDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form fields
                  Builder(
                    builder: (builderContext) {
                      // 포커스 리스너 설정 (한 번만 실행)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _setupAutoScroll(scrollController, 'dryFood', builderContext);
                        _setupAutoScroll(scrollController, 'wetFood', builderContext);
                        _setupAutoScroll(scrollController, 'supplement', builderContext);
                        _setupAutoScroll(scrollController, 'snack', builderContext);
                        _setupAutoScroll(scrollController, 'litter', builderContext);
                      });

                      return Flexible(
                        child: ListView(
                          controller: scrollController,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          children: [
                            AppTextField(
                              controller: _dryFoodController,
                              labelText: 'supplies.dry_food'.tr(),
                              prefixIcon: const Icon(Icons.restaurant),
                              hintText: 'supplies.dry_food_hint'.tr(),
                              focusNode: _focusNodes['dryFood'],
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _wetFoodController,
                              labelText: 'supplies.wet_food'.tr(),
                              prefixIcon: const Icon(Icons.rice_bowl),
                              hintText: 'supplies.wet_food_hint'.tr(),
                              focusNode: _focusNodes['wetFood'],
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _supplementController,
                              labelText: 'supplies.supplement'.tr(),
                              prefixIcon: const Icon(Icons.medication),
                              hintText: 'supplies.supplement_hint'.tr(),
                              focusNode: _focusNodes['supplement'],
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _snackController,
                              labelText: 'supplies.snack'.tr(),
                              prefixIcon: const Icon(Icons.cookie),
                              hintText: 'supplies.snack_hint'.tr(),
                              focusNode: _focusNodes['snack'],
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              controller: _litterController,
                              labelText: 'supplies.litter'.tr(),
                              prefixIcon: const Icon(Icons.cleaning_services),
                              hintText: 'supplies.litter_hint'.tr(),
                              focusNode: _focusNodes['litter'],
                            ),
                          ],
                        ),
                      );
                    },
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
                          onPressed: _updateSupplies,
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

  Future<void> _updateSupplies() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final now = DateTime.now();
      final supplies = PetSupplies(
        id: widget.existingSupplies?.id ?? const Uuid().v4(),
        petId: widget.pet.id,
        dryFood: _dryFoodController.text.trim().isEmpty ? null : _dryFoodController.text.trim(),
        wetFood: _wetFoodController.text.trim().isEmpty ? null : _wetFoodController.text.trim(),
        supplement: _supplementController.text.trim().isEmpty ? null : _supplementController.text.trim(),
        snack: _snackController.text.trim().isEmpty ? null : _snackController.text.trim(),
        litter: _litterController.text.trim().isEmpty ? null : _litterController.text.trim(),
        recordedAt: widget.selectedDate,
        createdAt: widget.existingSupplies?.createdAt ?? now,
        updatedAt: now,
    );

      AppLogger.d('PetDetail', '저장 시작: ${supplies.dryFood}, ${supplies.wetFood}, ${supplies.supplement}, ${supplies.snack}, ${supplies.litter}');
      final savedSupplies = await _suppliesRepository.saveSupplies(supplies);
      AppLogger.d('PetDetail', '저장 완료: ${savedSupplies?.dryFood}, ${savedSupplies?.wetFood}, ${savedSupplies?.supplement}');

      if (!mounted) {
        AppLogger.e('PetDetail', 'Widget disposed');
        return;
      }

      // 날짜 목록 로드
      final dates = await _suppliesRepository.getSuppliesRecordDates(widget.pet.id);
      AppLogger.d('PetDetail', '날짜 목록 로드: ${dates.length}개');

      // 콜백을 통해 부모에게 알림
      if (savedSupplies != null) {
        AppLogger.d('PetDetail', '콜백 호출: ${savedSupplies.dryFood}');
        widget.onSaved(savedSupplies, dates);
      }

      // 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('supplies.saved'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('supplies.save_failed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
