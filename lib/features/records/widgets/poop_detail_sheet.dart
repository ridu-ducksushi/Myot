import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petcare/features/records/widgets/poop_health_indicator.dart';

/// 배변 상세 기록 바텀시트 (색상, 농도, 횟수, 혈변/점액)
class PoopDetailSheet extends StatefulWidget {
  const PoopDetailSheet({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic> value, String note) onSave;

  @override
  State<PoopDetailSheet> createState() => _PoopDetailSheetState();
}

class _PoopDetailSheetState extends State<PoopDetailSheet> {
  late String _color;
  late String _consistency;
  late int _frequency;
  late bool _hasBlood;
  late bool _hasMucus;
  final _noteController = TextEditingController();

  static const _colorOptions = [
    'brown', 'dark_brown', 'yellow', 'green', 'red', 'black',
  ];

  static const _consistencyOptions = [
    'normal', 'soft', 'hard', 'liquid', 'mucus',
  ];

  static const Map<String, Color> _colorSwatches = {
    'brown': Color(0xFF8D6E63),
    'dark_brown': Color(0xFF4E342E),
    'yellow': Color(0xFFFDD835),
    'green': Color(0xFF66BB6A),
    'red': Color(0xFFEF5350),
    'black': Color(0xFF212121),
  };

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _color = v?['color'] as String? ?? 'brown';
    _consistency = v?['consistency'] as String? ?? 'normal';
    _frequency = v?['frequency'] as int? ?? 1;
    _hasBlood = v?['has_blood'] as bool? ?? false;
    _hasMucus = v?['has_mucus'] as bool? ?? false;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildValue() => {
    'color': _color,
    'consistency': _consistency,
    'frequency': _frequency,
    'has_blood': _hasBlood,
    'has_mucus': _hasMucus,
  };

  @override
  Widget build(BuildContext context) {
    final healthLevel = PoopHealthIndicator.evaluate(_buildValue());

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
            // 헤더
            Row(
              children: [
                Text(
                  'poop_detail.title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PoopHealthIndicator(level: healthLevel),
              ],
            ),
            const SizedBox(height: 16),

            // 색상 선택
            Text('poop_detail.color'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((c) {
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _colorSwatches[c],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text('poop_detail.color_$_color'.tr(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),

            // 농도 선택
            Text('poop_detail.consistency'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _consistencyOptions.map((c) {
                return ChoiceChip(
                  label: Text('poop_detail.consistency_$c'.tr()),
                  selected: _consistency == c,
                  onSelected: (s) {
                    if (s) setState(() => _consistency = c);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 횟수
            Row(
              children: [
                Text('poop_detail.frequency'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _frequency > 1
                      ? () => setState(() => _frequency--)
                      : null,
                ),
                Text('$_frequency', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _frequency++),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 혈변/점액
            SwitchListTile(
              title: Text('poop_detail.has_blood'.tr()),
              value: _hasBlood,
              onChanged: (v) => setState(() => _hasBlood = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: Text('poop_detail.has_mucus'.tr()),
              value: _hasMucus,
              onChanged: (v) => setState(() => _hasMucus = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 8),

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

            // 저장
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(_buildValue(), _noteController.text);
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
