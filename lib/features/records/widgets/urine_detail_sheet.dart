import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 소변 상세 기록 바텀시트
class UrineDetailSheet extends StatefulWidget {
  const UrineDetailSheet({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic> value, String note) onSave;

  @override
  State<UrineDetailSheet> createState() => _UrineDetailSheetState();
}

class _UrineDetailSheetState extends State<UrineDetailSheet> {
  late String _color;
  late int _frequency;
  final _noteController = TextEditingController();

  static const _colorOptions = [
    'clear', 'light_yellow', 'yellow', 'dark_yellow', 'orange', 'red',
  ];

  static const Map<String, Color> _colorSwatches = {
    'clear': Color(0xFFE0F7FA),
    'light_yellow': Color(0xFFFFF9C4),
    'yellow': Color(0xFFFDD835),
    'dark_yellow': Color(0xFFF9A825),
    'orange': Color(0xFFFF8F00),
    'red': Color(0xFFEF5350),
  };

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _color = v?['color'] as String? ?? 'yellow';
    _frequency = v?['frequency'] as int? ?? 1;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
              'urine_detail.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 색상 선택
            Text('urine_detail.color'.tr(),
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
                        ? Icon(Icons.check,
                            color: c == 'clear' ? Colors.black54 : Colors.white,
                            size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text('urine_detail.color_$_color'.tr(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),

            // 횟수
            Row(
              children: [
                Text('urine_detail.frequency'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _frequency > 1
                      ? () => setState(() => _frequency--)
                      : null,
                ),
                Text('$_frequency',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _frequency++),
                ),
              ],
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

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave({
                    'color': _color,
                    'frequency': _frequency,
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
