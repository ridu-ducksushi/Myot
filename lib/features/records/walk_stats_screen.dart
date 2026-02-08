import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/ui/theme/app_colors.dart';

/// Screen that shows weekly/monthly walk statistics
/// with a bar chart and summary totals.
class WalkStatsScreen extends ConsumerStatefulWidget {
  const WalkStatsScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<WalkStatsScreen> createState() => _WalkStatsScreenState();
}

class _WalkStatsScreenState extends ConsumerState<WalkStatsScreen> {
  String _viewMode = 'week'; // 'week' or 'month'

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final petName = pet?.name ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final allRecords = ref.watch(recordsForPetProvider(widget.petId));

    // Filter walk records
    final walkRecords = allRecords
        .where((r) =>
            r.type == 'activity_walk' ||
            r.type == 'activity_outing' ||
            r.type == 'walk')
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    final now = DateTime.now();
    final periodDays = _viewMode == 'week' ? 7 : 30;
    final dailyData = _buildDailyData(walkRecords, now, periodDays);
    final summary = _calculateSummary(dailyData, walkRecords, now, periodDays);

    return Scaffold(
      appBar: AppBar(
        title: Text('walk_stats.title'.tr(args: [petName])),
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
            // View mode selector
            Row(
              children: [
                ChoiceChip(
                  label: Text('walk_stats.weekly'.tr()),
                  selected: _viewMode == 'week',
                  onSelected: (selected) {
                    if (selected) setState(() => _viewMode = 'week');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('walk_stats.monthly'.tr()),
                  selected: _viewMode == 'month',
                  onSelected: (selected) {
                    if (selected) setState(() => _viewMode = 'month');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary cards
            _buildSummaryCards(context, colorScheme, summary),
            const SizedBox(height: 20),

            // Bar chart
            Text(
              'walk_stats.chart_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildBarChart(context, colorScheme, dailyData),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    ColorScheme colorScheme,
    _WalkSummary summary,
  ) {
    final primaryColor = AppColors.getRecordCategoryDarkColor('activity');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                context,
                icon: Icons.directions_walk,
                label: 'walk_stats.total_walks'.tr(),
                value: '${summary.totalWalks}',
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryTile(
                context,
                icon: Icons.timer,
                label: 'walk_stats.total_time'.tr(),
                value: _formatDuration(summary.totalMinutes),
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                context,
                icon: Icons.speed,
                label: 'walk_stats.avg_time'.tr(),
                value: _formatDuration(summary.avgMinutes),
                color: const Color(0xFF42A5F5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryTile(
                context,
                icon: Icons.straighten,
                label: 'walk_stats.total_distance'.tr(),
                value: '${summary.totalDistanceKm.toStringAsFixed(1)} km',
                color: const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    List<_DailyWalkData> data,
  ) {
    if (data.isEmpty || data.every((d) => d.totalMinutes == 0)) {
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
                Icon(Icons.directions_walk,
                    size: 48, color: colorScheme.outline),
                const SizedBox(height: 8),
                Text(
                  'walk_stats.no_data'.tr(),
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
        .map((d) => d.totalMinutes.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final chartMaxY = ((maxY * 1.2) / 10).ceil() * 10.0;
    final primaryColor = AppColors.getRecordCategoryDarkColor('activity');

    // For monthly view, show weekly aggregation for readability
    final displayData = _viewMode == 'month' && data.length > 14
        ? _aggregateToWeekly(data)
        : data;

    final displayMaxY = displayData
        .map((d) => d.totalMinutes.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final displayChartMaxY = ((displayMaxY * 1.2) / 10).ceil() * 10.0;

    final bottomInterval = displayData.length <= 7
        ? 1.0
        : (displayData.length / 7).ceilToDouble();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: displayChartMaxY > 0 ? displayChartMaxY : 60,
              minY: 0,
              barGroups: displayData.asMap().entries.map((entry) {
                final index = entry.key;
                final d = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: d.totalMinutes.toDouble(),
                      color: primaryColor,
                      width: _viewMode == 'week' ? 28 : 16,
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
                horizontalInterval:
                    displayChartMaxY > 0 ? displayChartMaxY / 4 : 15,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}m',
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
                    interval: bottomInterval,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= displayData.length) {
                        return const SizedBox.shrink();
                      }
                      final d = displayData[index];
                      final label = _viewMode == 'week'
                          ? DateFormat('E').format(d.date)
                          : DateFormat('MM/dd').format(d.date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
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
                    final d = displayData[group.x];
                    return BarTooltipItem(
                      '${DateFormat('MM/dd').format(d.date)}\n${d.totalMinutes} min (${d.walkCount} walks)',
                      Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    );
                  },
                ),
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

  List<_DailyWalkData> _buildDailyData(
    List<Record> walkRecords,
    DateTime now,
    int days,
  ) {
    final result = <_DailyWalkData>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dayRecords = walkRecords.where((r) {
        return r.at.year == date.year &&
            r.at.month == date.month &&
            r.at.day == date.day;
      }).toList();

      int totalMinutes = 0;
      double totalDistanceKm = 0;

      for (final r in dayRecords) {
        final walkData = _extractWalkData(r);
        totalMinutes += walkData.durationMinutes;
        totalDistanceKm += walkData.distanceKm;
      }

      result.add(_DailyWalkData(
        date: date,
        totalMinutes: totalMinutes,
        walkCount: dayRecords.length,
        totalDistanceKm: totalDistanceKm,
      ));
    }
    return result;
  }

  List<_DailyWalkData> _aggregateToWeekly(List<_DailyWalkData> dailyData) {
    // Group by week starting Monday
    final Map<String, List<_DailyWalkData>> grouped = {};
    for (final d in dailyData) {
      final weekday = d.date.weekday;
      final startOfWeek = d.date.subtract(Duration(days: weekday - 1));
      final key = DateFormat('yyyy-MM-dd').format(startOfWeek);
      grouped.putIfAbsent(key, () => []).add(d);
    }

    final result = <_DailyWalkData>[];
    final sortedKeys = grouped.keys.toList()..sort();
    for (final key in sortedKeys) {
      final week = grouped[key]!;
      final totalMin =
          week.fold<int>(0, (sum, d) => sum + d.totalMinutes);
      final totalWalks =
          week.fold<int>(0, (sum, d) => sum + d.walkCount);
      final totalDist = week.fold<double>(
          0, (sum, d) => sum + d.totalDistanceKm);
      result.add(_DailyWalkData(
        date: DateTime.parse(key),
        totalMinutes: totalMin,
        walkCount: totalWalks,
        totalDistanceKm: totalDist,
      ));
    }
    return result;
  }

  _WalkExtracted _extractWalkData(Record record) {
    int duration = 0;
    double distance = 0;

    if (record.value != null) {
      final v = record.value!;
      if (v.containsKey('duration_minutes')) {
        final d = v['duration_minutes'];
        if (d is int) duration = d;
        if (d is double) duration = d.round();
        if (d is String) duration = int.tryParse(d) ?? 0;
      }
      if (v.containsKey('distance_km')) {
        final d = v['distance_km'];
        if (d is num) distance = d.toDouble();
        if (d is String) distance = double.tryParse(d) ?? 0;
      }
    }

    return _WalkExtracted(durationMinutes: duration, distanceKm: distance);
  }

  _WalkSummary _calculateSummary(
    List<_DailyWalkData> dailyData,
    List<Record> walkRecords,
    DateTime now,
    int periodDays,
  ) {
    final periodStart =
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: periodDays));

    final periodRecords = walkRecords.where((r) => r.at.isAfter(periodStart));
    final totalWalks = periodRecords.length;
    final totalMinutes =
        dailyData.fold<int>(0, (sum, d) => sum + d.totalMinutes);
    final totalDistanceKm =
        dailyData.fold<double>(0, (sum, d) => sum + d.totalDistanceKm);
    final avgMinutes = totalWalks > 0 ? totalMinutes ~/ totalWalks : 0;

    return _WalkSummary(
      totalWalks: totalWalks,
      totalMinutes: totalMinutes,
      avgMinutes: avgMinutes,
      totalDistanceKm: totalDistanceKm,
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

class _DailyWalkData {
  const _DailyWalkData({
    required this.date,
    required this.totalMinutes,
    required this.walkCount,
    required this.totalDistanceKm,
  });

  final DateTime date;
  final int totalMinutes;
  final int walkCount;
  final double totalDistanceKm;
}

class _WalkExtracted {
  const _WalkExtracted({
    required this.durationMinutes,
    required this.distanceKm,
  });

  final int durationMinutes;
  final double distanceKm;
}

class _WalkSummary {
  const _WalkSummary({
    required this.totalWalks,
    required this.totalMinutes,
    required this.avgMinutes,
    required this.totalDistanceKm,
  });

  final int totalWalks;
  final int totalMinutes;
  final int avgMinutes;
  final double totalDistanceKm;
}
