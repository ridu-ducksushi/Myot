import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 산책 기록 바텀시트
class WalkRecordSheet extends StatefulWidget {
  const WalkRecordSheet({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  final Map<String, dynamic>? initialValue;
  final void Function(Map<String, dynamic> value, String note) onSave;

  @override
  State<WalkRecordSheet> createState() => _WalkRecordSheetState();
}

class _WalkRecordSheetState extends State<WalkRecordSheet> {
  late int _durationMinutes;
  final _distanceController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _noteController = TextEditingController();

  static const _quickDurations = [10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    _durationMinutes = v?['duration_minutes'] as int? ?? 30;
    final distance = v?['distance_km'];
    if (distance != null) {
      _distanceController.text = distance.toString();
    }
    _routeNameController.text = v?['route_name'] as String? ?? '';
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _routeNameController.dispose();
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
              'walk.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 시간 빠른 선택
            Text('walk.duration'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickDurations.map((d) {
                return ChoiceChip(
                  label: Text('walk.minutes'.tr(args: [d.toString()])),
                  selected: _durationMinutes == d,
                  onSelected: (s) {
                    if (s) setState(() => _durationMinutes = d);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // 커스텀 시간 슬라이더
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$_durationMinutes',
                    onChanged: (v) =>
                        setState(() => _durationMinutes = v.round()),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'walk.minutes'.tr(args: [_durationMinutes.toString()]),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 거리 (선택)
            TextField(
              controller: _distanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'walk.distance'.tr(),
                suffixText: 'km',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 경로명 (선택)
            TextField(
              controller: _routeNameController,
              decoration: InputDecoration(
                labelText: 'walk.route_name'.tr(),
                hintText: 'walk.route_name_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
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
                  final value = <String, dynamic>{
                    'duration_minutes': _durationMinutes,
                  };
                  final dist =
                      double.tryParse(_distanceController.text.trim());
                  if (dist != null && dist > 0) {
                    value['distance_km'] = dist;
                  }
                  final route = _routeNameController.text.trim();
                  if (route.isNotEmpty) {
                    value['route_name'] = route;
                  }
                  widget.onSave(value, _noteController.text);
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
