import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/reminders_provider.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petcare/data/services/lab_reference_ranges.dart';
import 'package:petcare/data/services/ocr_service.dart';
import 'package:petcare/utils/date_utils.dart' as app_date_utils;
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'weight_chart_screen.dart';
import 'ocr_result_screen.dart';
import 'widgets/reminder_section.dart';
import 'widgets/lab_table.dart';
import 'widgets/add_lab_item_dialog.dart';

class PetHealthScreen extends ConsumerStatefulWidget {
  const PetHealthScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetHealthScreen> createState() => _PetHealthScreenState();
}

class _PetHealthScreenState extends ConsumerState<PetHealthScreen> {
  // 건강 차트 테이블에 접근하기 위한 키 (새 검사 항목 추가 시 현재 날짜만 다시 로드)
  final GlobalKey<LabTableState> _labTableKey = GlobalKey<LabTableState>();
  @override
  void initState() {
    super.initState();
    // Load reminders for this specific pet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remindersProvider.notifier).loadReminders(widget.petId);
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text('tabs.health'.tr()),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withOpacity(0.95),
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: LabTable(
        key: _labTableKey,
        species: pet.species,
        petId: pet.id,
        petName: pet.name,
        petWeight: pet.weightKg,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(pet),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showWeightChartDialog(String petId, String petName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeightChartScreen(petId: petId, petName: petName),
      ),
    );
  }

  void _showAddOptions(Pet pet) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'labs.add_test_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text('labs.manual_input'.tr()),
                subtitle: Text('labs.manual_input_subtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog(pet.species, pet.id);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                title: Text('labs.ocr_scan'.tr()),
                subtitle: Text('labs.ocr_scan_subtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _showOcrOptions(pet);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String species, String petId) {
    showDialog(
      context: context,
      builder: (context) => AddLabItemDialog(
        species: species,
        petId: petId,
        onItemAdded: () {
          // 새 검사 항목이 추가되면 현재 선택된 날짜만 다시 로드
          // (날짜는 유지하고 내용만 갱신)
          _labTableKey.currentState?.reloadCurrentDate();
        },
      ),
    );
  }

  void _showOcrOptions(Pet pet) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'labs.scan_health_report'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'labs.scan_description'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'labs.ocr_tips'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    _buildOcrTip('labs.ocr_tip_1'.tr()),
                    _buildOcrTip('labs.ocr_tip_2'.tr()),
                    _buildOcrTip('labs.ocr_tip_3'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text('labs.camera_capture'.tr()),
                subtitle: Text('labs.camera_capture_subtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _startOcrFromCamera(pet);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text('labs.gallery_select'.tr()),
                subtitle: Text('labs.gallery_select_subtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _startOcrFromGallery(pet);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 이미지 선택 및 OCR 처리 (카메라/갤러리 공통)
  Future<void> _startOcrFromSource(Pet pet, ImageSource source) async {
    try {
      final imageFile = source == ImageSource.camera
          ? await OcrService.pickFromCamera()
          : await OcrService.pickFromGallery();

      if (imageFile != null && mounted) {
        await _navigateToOcrResult(imageFile, pet);
      } else if (mounted && source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('labs.camera_canceled'.tr())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showImagePickerError(e, source);
    }
  }

  /// 이미지 선택 오류 메시지 표시
  void _showImagePickerError(dynamic error, ImageSource source) {
    final isCamera = source == ImageSource.camera;
    final errorStr = error.toString();

    String message = isCamera
        ? 'labs.camera_unavailable'.tr()
        : 'labs.gallery_unavailable'.tr();

    if (errorStr.contains('permission') || errorStr.contains('권한')) {
      message = isCamera
          ? 'labs.camera_permission'.tr()
          : 'labs.gallery_permission'.tr();
    } else if (errorStr.contains('camera') || errorStr.contains('카메라')) {
      message = 'labs.camera_in_use'.tr();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startOcrFromCamera(Pet pet) async {
    await _startOcrFromSource(pet, ImageSource.camera);
  }

  Future<void> _startOcrFromGallery(Pet pet) async {
    await _startOcrFromSource(pet, ImageSource.gallery);
  }

  Future<void> _navigateToOcrResult(File imageFile, Pet pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OcrResultScreen(
          imageFile: imageFile,
          species: pet.species,
          existingKeys: LabReferenceRanges.getAllTestKeys(),
          onConfirm: (results) => _applyOcrResults(pet, results),
        ),
      ),
    );
  }

  Future<void> _applyOcrResults(Pet pet, Map<String, String> results) async {
    if (results.isEmpty) return;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('labs.login_required'.tr())),
          );
        }
        return;
      }

      final dateKey = app_date_utils.DateUtils.toDateKey(DateTime.now());

      // 현재 날짜의 기존 데이터 가져오기
      final currentRes = await Supabase.instance.client
          .from('labs')
          .select('items')
          .eq('user_id', uid)
          .eq('pet_id', pet.id)
          .eq('date', dateKey)
          .eq('panel', 'BloodTest')
          .maybeSingle();

      Map<String, dynamic> currentItems = {};
      if (currentRes != null) {
        currentItems = Map<String, dynamic>.from(currentRes['items'] ?? {});
      }

      // OCR 결과 추가
      for (final entry in results.entries) {
        final reference = LabReferenceRanges.getReference(
          pet.species,
          entry.key,
        );
        currentItems[entry.key] = {
          'value': entry.value,
          'unit': _getDefaultUnit(entry.key),
          'reference': reference,
        };
      }

      // Supabase에 저장
      await Supabase.instance.client.from('labs').upsert({
        'user_id': uid,
        'pet_id': pet.id,
        'date': dateKey,
        'panel': 'BloodTest',
        'items': currentItems,
      }, onConflict: 'user_id,pet_id,date');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('labs.items_saved'.tr(namedArgs: {'count': results.length.toString()})),
            backgroundColor: Colors.green,
          ),
        );
        // 화면 새로고침
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('labs.save_ocr_error'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  String _getDefaultUnit(String testName) {
    const units = {
      'ALB': 'g/dL',
      'ALP': 'U/L',
      'ALT GPT': 'U/L',
      'AST GOT': 'U/L',
      'BUN': 'mg/dL',
      'Ca': 'mg/dL',
      'CK': 'U/L',
      'Cl': 'mmol/L',
      'CREA': 'mg/dL',
      'GGT': 'U/L',
      'GLU': 'mg/dL',
      'K': 'mmol/L',
      'LIPA': 'U/L',
      'Na': 'mmol/L',
      'NH3': 'µmol/L',
      'PHOS': 'mg/dL',
      'TBIL': 'mg/dL',
      'T-CHOL': 'mg/dL',
      'TG': 'mg/dL',
      'TPRO': 'g/dL',
      'HCT': '%',
      'HGB': 'g/dL',
      'MCH': 'pg',
      'MCHC': 'g/dL',
      'MCV': 'fL',
      'MPV': 'fL',
      'PLT': '10⁹/L',
      'RBC': '10x12/L',
      'RDW-CV': '%',
      'WBC': '10⁹/L',
    };
    return units[testName] ?? '';
  }
}
