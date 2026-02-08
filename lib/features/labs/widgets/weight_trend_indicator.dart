import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Shows a trend arrow (up/down/stable) based on recent weight changes.
///
/// Color coded:
/// - Green for stable/improving
/// - Yellow for mild change
/// - Red for significant change
class WeightTrendIndicator extends StatelessWidget {
  const WeightTrendIndicator({
    super.key,
    required this.trend,
    this.recentWeights = const [],
  });

  /// One of: 'increasing', 'decreasing', 'stable', 'unknown'.
  final String trend;

  /// Recent weight entries for computing magnitude.
  /// Each entry: {'date': DateTime, 'weight': double}.
  final List<Map<String, dynamic>> recentWeights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final trendData = _getTrendData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: trendData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendData.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: trendData.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trendData.icon,
              color: trendData.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trendData.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: trendData.color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  trendData.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          if (_getChangeText() != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trendData.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getChangeText()!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: trendData.color,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  _TrendDisplayData _getTrendData() {
    final magnitude = _calculateMagnitude();

    switch (trend) {
      case 'increasing':
        if (magnitude > 0.1) {
          return _TrendDisplayData(
            icon: Icons.trending_up,
            color: const Color(0xFFEF5350),
            label: 'weight_guide.trend_increasing'.tr(),
            description: 'weight_guide.trend_increasing_desc'.tr(),
          );
        }
        return _TrendDisplayData(
          icon: Icons.trending_up,
          color: const Color(0xFFFFCA28),
          label: 'weight_guide.trend_increasing'.tr(),
          description: 'weight_guide.trend_mild_increase_desc'.tr(),
        );

      case 'decreasing':
        if (magnitude > 0.1) {
          return _TrendDisplayData(
            icon: Icons.trending_down,
            color: const Color(0xFFEF5350),
            label: 'weight_guide.trend_decreasing'.tr(),
            description: 'weight_guide.trend_decreasing_desc'.tr(),
          );
        }
        return _TrendDisplayData(
          icon: Icons.trending_down,
          color: const Color(0xFFFFCA28),
          label: 'weight_guide.trend_decreasing'.tr(),
          description: 'weight_guide.trend_mild_decrease_desc'.tr(),
        );

      case 'stable':
        return _TrendDisplayData(
          icon: Icons.trending_flat,
          color: const Color(0xFF66BB6A),
          label: 'weight_guide.trend_stable'.tr(),
          description: 'weight_guide.trend_stable_desc'.tr(),
        );

      default:
        return _TrendDisplayData(
          icon: Icons.help_outline,
          color: Colors.grey,
          label: 'weight_guide.trend_unknown'.tr(),
          description: 'weight_guide.trend_unknown_desc'.tr(),
        );
    }
  }

  /// Calculate the magnitude of weight change (as a fraction of the first weight).
  double _calculateMagnitude() {
    if (recentWeights.length < 2) return 0;
    final first = recentWeights.first['weight'] as double;
    final last = recentWeights.last['weight'] as double;
    if (first <= 0) return 0;
    return ((last - first) / first).abs();
  }

  String? _getChangeText() {
    if (recentWeights.length < 2) return null;
    final first = recentWeights.first['weight'] as double;
    final last = recentWeights.last['weight'] as double;
    final diff = last - first;
    if (diff.abs() < 0.05) return null;
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} kg';
  }
}

class _TrendDisplayData {
  const _TrendDisplayData({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String description;
}
