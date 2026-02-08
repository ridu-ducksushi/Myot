import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 음수량 기록 바텀시트
class WaterIntakeSheet extends StatefulWidget {
  const WaterIntakeSheet({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic> value, String note) onSave;

  @override
  State<WaterIntakeSheet> createState() => _WaterIntakeSheetState();
}

class _WaterIntakeSheetState extends State<WaterIntakeSheet> {
  late int _amountMl;
  late String _method;
  final _customController = TextEditingController();
  final _noteController = TextEditingController();

  static const _quickAmounts = [50, 100, 150, 200, 250, 300];
  static const _methods = ['bowl', 'fountain', 'syringe', 'other'];

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _amountMl = v?['amount_ml'] as int? ?? 100;
    _method = v?['method'] as String? ?? 'bowl';
    _customController.text = _amountMl.toString();
  }

  @override
  void dispose() {
    _customController.dispose();
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
              'water_intake.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 빠른 선택 버튼
            Text('water_intake.quick_select'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final selected = _amountMl == amount;
                return ChoiceChip(
                  label: Text('${amount}ml'),
                  selected: selected,
                  onSelected: (s) {
                    if (s) {
                      setState(() {
                        _amountMl = amount;
                        _customController.text = amount.toString();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 커스텀 입력
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'water_intake.custom_amount'.tr(),
                suffixText: 'ml',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  setState(() => _amountMl = parsed);
                }
              },
            ),
            const SizedBox(height: 16),

            // 급수 방법
            Text('water_intake.method'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _methods.map((m) {
                return ChoiceChip(
                  label: Text('water_intake.method_$m'.tr()),
                  selected: _method == m,
                  onSelected: (s) {
                    if (s) setState(() => _method = m);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

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
                    'amount_ml': _amountMl,
                    'unit': 'ml',
                    'method': _method,
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
