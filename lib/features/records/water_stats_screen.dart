import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/ui/theme/app_colors.dart';

/// Screen that shows daily water intake statistics
/// with a 7-day average bar chart and deviation alerts.
class WaterStatsScreen extends ConsumerStatefulWidget {
  const WaterStatsScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<WaterStatsScreen> createState() => _WaterStatsScreenState();
}

class _WaterStatsScreenState extends ConsumerState<WaterStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final petName = pet?.name ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final allRecords = ref.watch(recordsForPetProvider(widget.petId));

    // Filter water records
    final waterRecords = allRecords
        .where((r) => r.type == 'food_water' || r.type == 'water')
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    // Build daily totals for the last 14 days
    final now = DateTime.now();
    final dailyData = _buildDailyData(waterRecords, now, 14);
    final last7Days = dailyData.length > 7
        ? dailyData.sublist(dailyData.length - 7)
        : dailyData;

    // Calculate stats
    final todayTotal = _getTodayTotal(waterRecords, now);
    final sevenDayAvg = _calculateAverage(last7Days);
    final deviationPercent = sevenDayAvg > 0
        ? ((todayTotal - sevenDayAvg) / sevenDayAvg * 100).round()
        : 0;
    final hasDeviation = deviationPercent.abs() > 30;

    return Scaffold(
      appBar: AppBar(
        title: Text('water_stats.title'.tr(args: [petName])),
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
            // Today's total card
            _buildTodayCard(context, colorScheme, todayTotal),
            const SizedBox(height: 16),

            // Deviation alert banner
            if (hasDeviation)
              _buildDeviationBanner(
                  context, colorScheme, deviationPercent, sevenDayAvg),
            if (hasDeviation) const SizedBox(height: 16),

            // 7-day average
            _buildAverageCard(context, colorScheme, sevenDayAvg),
            const SizedBox(height: 20),

            // Bar chart
            Text(
              'water_stats.chart_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildBarChart(context, colorScheme, last7Days, sevenDayAvg),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(
    BuildContext context,
    ColorScheme colorScheme,
    int todayTotal,
  ) {
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop,
                color: Color(0xFF42A5F5),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'water_stats.today'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$todayTotal ml',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF42A5F5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviationBanner(
    BuildContext context,
    ColorScheme colorScheme,
    int deviationPercent,
    double average,
  ) {
    final isHigh = deviationPercent > 0;
    final bannerColor = isHigh
        ? const Color(0xFFFF9800)
        : const Color(0xFF42A5F5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: bannerColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh
                      ? 'water_stats.deviation_high'.tr()
                      : 'water_stats.deviation_low'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: bannerColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'water_stats.deviation_detail'.tr(args: [
                    deviationPercent.abs().toString(),
                    average.round().toString(),
                  ]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(
    BuildContext context,
    ColorScheme colorScheme,
    double average,
  ) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'water_stats.seven_day_avg'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '${average.round()} ml',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    ColorScheme colorScheme,
    List<_DailyWaterData> data,
    double average,
  ) {
    if (data.isEmpty) {
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.water_drop_outlined,
                    size: 48, color: colorScheme.outline),
                const SizedBox(height: 8),
                Text(
                  'water_stats.no_data'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxY = data
        .map((d) => d.totalMl.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final chartMaxY = ((maxY * 1.2) / 50).ceil() * 50.0;

    final primaryColor = AppColors.getRecordCategoryDarkColor('food');
    final softColor = AppColors.getRecordCategorySoftColor('food');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: 0,
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final d = entry.value;
                final isAboveAvg =
                    average > 0 && d.totalMl > average * 1.3;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: d.totalMl.toDouble(),
                      color:
                          isAboveAvg ? const Color(0xFFFF9800) : primaryColor,
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('E').format(data[index].date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final d = data[group.x];
                    return BarTooltipItem(
                      '${DateFormat('MM/dd').format(d.date)}\n${d.totalMl} ml',
                      Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    );
                  },
                ),
              ),
              // Average line
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (average > 0)
                    HorizontalLine(
                      y: average,
                      color: const Color(0xFF66BB6A),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF66BB6A),
                                  fontWeight: FontWeight.w600,
                                ) ??
                            const TextStyle(),
                        labelResolver: (_) =>
                            'Avg: ${average.round()} ml',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Data processing helpers
  // -----------------------------------------------------------------------

  List<_DailyWaterData> _buildDailyData(
    List<Record> waterRecords,
    DateTime now,
    int days,
  ) {
    final result = <_DailyWaterData>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dayRecords = waterRecords.where((r) {
        return r.at.year == date.year &&
            r.at.month == date.month &&
            r.at.day == date.day;
      });

      int totalMl = 0;
      for (final r in dayRecords) {
        totalMl += _extractWaterAmount(r);
      }

      result.add(_DailyWaterData(date: date, totalMl: totalMl));
    }
    return result;
  }

  int _getTodayTotal(List<Record> waterRecords, DateTime now) {
    final todayRecords = waterRecords.where((r) {
      return r.at.year == now.year &&
          r.at.month == now.month &&
          r.at.day == now.day;
    });

    int total = 0;
    for (final r in todayRecords) {
      total += _extractWaterAmount(r);
    }
    return total;
  }

  int _extractWaterAmount(Record record) {
    if (record.value != null) {
      final v = record.value!;
      if (v.containsKey('amount_ml')) {
        final amount = v['amount_ml'];
        if (amount is int) return amount;
        if (amount is double) return amount.round();
        if (amount is String) return int.tryParse(amount) ?? 0;
      }
    }
    if (record.content != null && record.content!.isNotEmpty) {
      final parsed = int.tryParse(
          record.content!.replaceAll(RegExp(r'[^0-9]'), ''));
      return parsed ?? 0;
    }
    return 0;
  }

  double _calculateAverage(List<_DailyWaterData> data) {
    if (data.isEmpty) return 0;
    final nonZero = data.where((d) => d.totalMl > 0).toList();
    if (nonZero.isEmpty) return 0;
    final total = nonZero.fold<int>(0, (sum, d) => sum + d.totalMl);
    return total / nonZero.length;
  }
}

class _DailyWaterData {
  const _DailyWaterData({
    required this.date,
    required this.totalMl,
  });

  final DateTime date;
  final int totalMl;
}
