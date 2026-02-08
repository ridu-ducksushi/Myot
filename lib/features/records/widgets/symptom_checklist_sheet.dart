import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 증상 체크리스트 기록 바텀시트
class SymptomChecklistSheet extends StatefulWidget {
  const SymptomChecklistSheet({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic> value, String note) onSave;

  @override
  State<SymptomChecklistSheet> createState() => _SymptomChecklistSheetState();
}

class _SymptomChecklistSheetState extends State<SymptomChecklistSheet> {
  late String _appetite;
  late String _energy;
  late bool _vomiting;
  late bool _diarrhea;
  late bool _coughing;
  late String _skinCondition;
  late String _eyeDischarge;
  late String _noseDischarge;
  late List<String> _customSymptoms;
  final _customSymptomController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _appetite = v?['appetite'] as String? ?? 'normal';
    _energy = v?['energy'] as String? ?? 'normal';
    _vomiting = v?['vomiting'] as bool? ?? false;
    _diarrhea = v?['diarrhea'] as bool? ?? false;
    _coughing = v?['coughing'] as bool? ?? false;
    _skinCondition = v?['skin_condition'] as String? ?? 'normal';
    _eyeDischarge = v?['eye_discharge'] as String? ?? 'none';
    _noseDischarge = v?['nose_discharge'] as String? ?? 'none';
    _customSymptoms = List<String>.from(
        (v?['custom_symptoms'] as List<dynamic>?) ?? []);
  }

  @override
  void dispose() {
    _customSymptomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildChoiceRow(String label, String currentValue,
      List<String> options, void Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            return ChoiceChip(
              label: Text('symptom.$opt'.tr()),
              selected: currentValue == opt,
              onSelected: (s) {
                if (s) onChanged(opt);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'symptom.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 식욕
            _buildChoiceRow(
              'symptom.appetite'.tr(), _appetite,
              ['good', 'normal', 'poor'],
              (v) => setState(() => _appetite = v),
            ),

            // 활력
            _buildChoiceRow(
              'symptom.energy'.tr(), _energy,
              ['active', 'normal', 'lethargic'],
              (v) => setState(() => _energy = v),
            ),

            // 토글 증상들
            SwitchListTile(
              title: Text('symptom.vomiting'.tr()),
              value: _vomiting,
              onChanged: (v) => setState(() => _vomiting = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: Text('symptom.diarrhea'.tr()),
              value: _diarrhea,
              onChanged: (v) => setState(() => _diarrhea = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: Text('symptom.coughing'.tr()),
              value: _coughing,
              onChanged: (v) => setState(() => _coughing = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 8),

            // 피부
            _buildChoiceRow(
              'symptom.skin_condition'.tr(), _skinCondition,
              ['normal', 'dry', 'rash', 'itchy'],
              (v) => setState(() => _skinCondition = v),
            ),

            // 눈 분비물
            _buildChoiceRow(
              'symptom.eye_discharge'.tr(), _eyeDischarge,
              ['none', 'mild', 'severe'],
              (v) => setState(() => _eyeDischarge = v),
            ),

            // 코 분비물
            _buildChoiceRow(
              'symptom.nose_discharge'.tr(), _noseDischarge,
              ['none', 'mild', 'severe'],
              (v) => setState(() => _noseDischarge = v),
            ),

            // 커스텀 증상
            Text('symptom.custom'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_customSymptoms.isNotEmpty)
              Wrap(
                spacing: 6,
                children: _customSymptoms.map((s) {
                  return Chip(
                    label: Text(s),
                    onDeleted: () {
                      setState(() => _customSymptoms.remove(s));
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSymptomController,
                    decoration: InputDecoration(
                      hintText: 'symptom.custom_hint'.tr(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    final text = _customSymptomController.text.trim();
                    if (text.isNotEmpty && !_customSymptoms.contains(text)) {
                      setState(() {
                        _customSymptoms.add(text);
                        _customSymptomController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 메모
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'records.dialog.note_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave({
                    'appetite': _appetite,
                    'energy': _energy,
                    'vomiting': _vomiting,
                    'diarrhea': _diarrhea,
                    'coughing': _coughing,
                    'skin_condition': _skinCondition,
                    'eye_discharge': _eyeDischarge,
                    'nose_discharge': _noseDischarge,
                    if (_customSymptoms.isNotEmpty)
                      'custom_symptoms': _customSymptoms,
                  }, _noteController.text);
                },
                child: Text('common.save'.tr()),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
