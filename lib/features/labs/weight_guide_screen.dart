import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/weight_guide_provider.dart';
import 'package:petcare/features/labs/widgets/weight_gauge_widget.dart';
import 'package:petcare/features/labs/widgets/weight_trend_indicator.dart';

/// Screen that shows the current weight vs breed ideal range,
/// a horizontal gauge widget, and a weight trend indicator.
class WeightGuideScreen extends ConsumerStatefulWidget {
  const WeightGuideScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<WeightGuideScreen> createState() => _WeightGuideScreenState();
}

class _WeightGuideScreenState extends ConsumerState<WeightGuideScreen> {
  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final guideData = ref.watch(weightGuideProvider(widget.petId));
    final colorScheme = Theme.of(context).colorScheme;
    final petName = pet?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('weight_guide.title'.tr(args: [petName])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current weight summary card
            _buildSummaryCard(context, guideData, colorScheme),
            const SizedBox(height: 20),

            // Weight gauge
            if (guideData.breedRange != null &&
                guideData.currentWeightKg != null) ...[
              Text(
                'weight_guide.gauge_title'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: WeightGaugeWidget(
                    currentWeight: guideData.currentWeightKg!,
                    minIdeal: guideData.breedRange!.minWeightKg,
                    maxIdeal: guideData.breedRange!.maxWeightKg,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              _buildNoBreedDataCard(context, colorScheme),
              const SizedBox(height: 20),
            ],

            // Weight trend indicator
            Text(
              'weight_guide.trend_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            WeightTrendIndicator(
              trend: guideData.trend ?? 'unknown',
              recentWeights: guideData.recentWeights,
            ),
            const SizedBox(height: 20),

            // Breed info
            if (guideData.breedRange != null) ...[
              Text(
                'weight_guide.breed_info_title'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _buildBreedInfoCard(context, guideData, colorScheme),
            ],

            // Recent weight history
            if (guideData.recentWeights.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'weight_guide.history_title'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _buildWeightHistory(context, guideData, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    WeightGuideData data,
    ColorScheme colorScheme,
  ) {
    final statusColor = _statusColor(data.weightStatus);
    final statusLabel = _statusLabel(data.weightStatus);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monitor_weight_rounded,
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.currentWeightKg != null
                        ? '${data.currentWeightKg!.toStringAsFixed(1)} kg'
                        : 'weight_guide.no_weight'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (data.breed != null && data.breed!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data.breed!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBreedDataCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 40,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'weight_guide.no_breed_data'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedInfoCard(
    BuildContext context,
    WeightGuideData data,
    ColorScheme colorScheme,
  ) {
    final range = data.breedRange!;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breedInfoRow(
              context,
              'weight_guide.breed_name'.tr(),
              range.breedName,
            ),
            const Divider(height: 16),
            _breedInfoRow(
              context,
              'weight_guide.ideal_range'.tr(),
              '${range.minWeightKg.toStringAsFixed(1)} ~ ${range.maxWeightKg.toStringAsFixed(1)} kg',
            ),
            const Divider(height: 16),
            _breedInfoRow(
              context,
              'weight_guide.ideal_mid'.tr(),
              '${range.midWeightKg.toStringAsFixed(1)} kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _breedInfoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildWeightHistory(
    BuildContext context,
    WeightGuideData data,
    ColorScheme colorScheme,
  ) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    // Show most recent first, limit to 10
    final weights = data.recentWeights.reversed.take(10).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: weights.map((entry) {
            final date = entry['date'] as DateTime;
            final weight = entry['weight'] as double;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateFmt.format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'underweight':
        return const Color(0xFF42A5F5);
      case 'normal':
        return const Color(0xFF66BB6A);
      case 'overweight':
        return const Color(0xFFFFCA28);
      case 'obese':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'underweight':
        return 'weight_guide.status_underweight'.tr();
      case 'normal':
        return 'weight_guide.status_normal'.tr();
      case 'overweight':
        return 'weight_guide.status_overweight'.tr();
      case 'obese':
        return 'weight_guide.status_obese'.tr();
      default:
        return 'weight_guide.status_unknown'.tr();
    }
  }
}
