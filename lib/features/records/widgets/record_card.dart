import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/ui/theme/app_colors.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';
import 'package:petcare/utils/app_constants.dart';
import 'package:petcare/utils/record_utils.dart';
import 'package:petcare/features/records/widgets/poop_health_indicator.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, required this.pet});

  final Record record;
  final Pet pet;

  Widget _buildValueSummary(BuildContext context, Record record) {
    final value = record.value!;
    final chips = <Widget>[];

    switch (record.type) {
      case 'food_water':
        final amount = value['amount_ml'];
        if (amount != null) {
          chips.add(_chip(context, '${amount}ml', Icons.water_drop));
        }
        final method = value['method'] as String?;
        if (method != null) {
          chips.add(_chip(context, 'water_intake.method_$method'.tr(), null));
        }
        break;
      case 'activity_walk':
        final dur = value['duration_minutes'];
        if (dur != null) {
          chips.add(_chip(context, 'walk.minutes'.tr(args: [dur.toString()]), Icons.timer));
        }
        final dist = value['distance_km'];
        if (dist != null) {
          chips.add(_chip(context, '${dist}km', Icons.straighten));
        }
        break;
      case 'poop_feces':
        final color = value['color'] as String?;
        if (color != null) {
          chips.add(_chip(context, 'poop_detail.color_$color'.tr(), null));
        }
        final consistency = value['consistency'] as String?;
        if (consistency != null) {
          chips.add(_chip(context, 'poop_detail.consistency_$consistency'.tr(), null));
        }
        break;
      case 'poop_urine':
        final color = value['color'] as String?;
        if (color != null) {
          chips.add(_chip(context, 'urine_detail.color_$color'.tr(), null));
        }
        break;
      case 'health_symptom':
        final appetite = value['appetite'] as String?;
        if (appetite != null && appetite != 'normal') {
          chips.add(_chip(context, 'symptom.appetite'.tr() + ': ' + 'symptom.$appetite'.tr(), null));
        }
        final energy = value['energy'] as String?;
        if (energy != null && energy != 'normal') {
          chips.add(_chip(context, 'symptom.energy'.tr() + ': ' + 'symptom.$energy'.tr(), null));
        }
        if (value['vomiting'] == true) chips.add(_chip(context, 'symptom.vomiting'.tr(), Icons.warning_amber));
        if (value['diarrhea'] == true) chips.add(_chip(context, 'symptom.diarrhea'.tr(), Icons.warning_amber));
        break;
      case 'grooming':
        final subType = value['subType'] as String?;
        if (subType != null) {
          chips.add(_chip(context, 'grooming.sub_$subType'.tr(), null));
        }
        break;
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }

  Widget _chip(BuildContext context, String label, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 3),
          ],
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.getRecordTypeColor(record.type);
    final content = record.content;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallSpacing),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    RecordUtils.getIconForAnyType(record.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.mediumSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RecordUtils.getLabelForType(context, record.type),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm').format(record.at),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.smallSpacing,
                    vertical: AppConstants.xSmallSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.type.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // 건강 지표 배지 (배변 기록)
            if (record.type == 'poop_feces' && record.value != null) ...[
              const SizedBox(height: AppConstants.smallSpacing),
              PoopHealthIndicator(
                level: PoopHealthIndicator.evaluate(record.value),
              ),
            ],
            // 값 요약 표시
            if (record.value != null && record.value!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.smallSpacing),
              _buildValueSummary(context, record),
            ],
            if (content != null && content.isNotEmpty) ...[
              const SizedBox(height: AppConstants.mediumSpacing),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
