import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:petcare/core/providers/health_report_provider.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/data/models/health_report.dart';
import 'package:petcare/data/services/health_report_service.dart';
import 'package:petcare/features/labs/widgets/report_section_card.dart';

/// Screen that displays a comprehensive health report for a pet.
///
/// Allows selecting a reporting period (1/3/6/12 months) and
/// previews sections in cards. Provides a share button.
class HealthReportScreen extends ConsumerStatefulWidget {
  const HealthReportScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  ConsumerState<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends ConsumerState<HealthReportScreen> {
  int _selectedMonths = 3;

  DateTime get _startDate =>
      DateTime.now().subtract(Duration(days: _selectedMonths * 30));
  DateTime get _endDate => DateTime.now();

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final petName = pet?.name ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    final params = HealthReportParams(
      petId: widget.petId,
      startDate: _startDate,
      endDate: _endDate,
    );
    final reportAsync = ref.watch(healthReportProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text('health_report.title'.tr(args: [petName])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          reportAsync.maybeWhen(
            data: (report) {
              if (report == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'health_report.share'.tr(),
                onPressed: () => _shareReport(report),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'health_report.period_label'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _periodChip(1),
                    const SizedBox(width: 8),
                    _periodChip(3),
                    const SizedBox(width: 8),
                    _periodChip(6),
                    const SizedBox(width: 8),
                    _periodChip(12),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy-MM-dd').format(_startDate)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
          // Report content
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 8),
                    Text(
                      'health_report.error'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              data: (report) {
                if (report == null) {
                  return Center(
                    child: Text('health_report.no_pet'.tr()),
                  );
                }
                return _buildReportContent(report);
              },
            ),
          ),
        ],
      ),
      // Floating share button
      floatingActionButton: reportAsync.maybeWhen(
        data: (report) {
          if (report == null) return null;
          return FloatingActionButton.extended(
            onPressed: () => _shareReport(report),
            icon: const Icon(Icons.share),
            label: Text('health_report.share'.tr()),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _periodChip(int months) {
    final isSelected = _selectedMonths == months;
    return ChoiceChip(
      label: Text('health_report.months'.tr(args: [months.toString()])),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedMonths = months);
        }
      },
    );
  }

  Widget _buildReportContent(HealthReport report) {
    final dateFmt = DateFormat('yyyy-MM-dd');

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        // Basic Info
        ReportSectionCard(
          title: 'health_report.section_basic_info'.tr(),
          icon: Icons.pets,
          iconColor: const Color(0xFF42A5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('health_report.name'.tr(), report.petName),
              _infoRow('health_report.species'.tr(), report.species),
              if (report.breed != null && report.breed!.isNotEmpty)
                _infoRow('health_report.breed'.tr(), report.breed!),
              if (report.weightKg != null)
                _infoRow('health_report.weight'.tr(),
                    '${report.weightKg!.toStringAsFixed(1)} kg'),
            ],
          ),
        ),

        // Weight Trend
        ReportSectionCard(
          title: 'health_report.section_weight_trend'.tr(),
          icon: Icons.monitor_weight_rounded,
          iconColor: const Color(0xFF66BB6A),
          child: report.weightHistory.isEmpty
              ? Text(
                  'health_report.no_weight_data'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...report.weightHistory.map((entry) {
                      final date = entry['date'] as DateTime;
                      final weight = entry['weight'] as double;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
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
                    }),
                    const SizedBox(height: 4),
                    _buildWeightSummary(report.weightHistory),
                  ],
                ),
        ),

        // Lab Results
        ReportSectionCard(
          title: 'health_report.section_lab_results'.tr(),
          icon: Icons.science,
          iconColor: const Color(0xFFAB47BC),
          child: report.recentLabResults.isEmpty
              ? Text(
                  'health_report.no_lab_data'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.recentLabResults.map((lab) {
                    final panel = lab['panel'] as String;
                    final measuredAt = lab['measuredAt'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$panel (${dateFmt.format(measuredAt)})',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ..._buildLabItems(lab['items'] as Map<String, dynamic>),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        // Vaccinations
        ReportSectionCard(
          title: 'health_report.section_vaccinations'.tr(),
          icon: Icons.vaccines,
          iconColor: const Color(0xFF26A69A),
          child: _buildRecordList(report.vaccinationRecords),
        ),

        // Hospital Visits
        ReportSectionCard(
          title: 'health_report.section_hospital_visits'.tr(),
          icon: Icons.local_hospital,
          iconColor: const Color(0xFFEF5350),
          child: _buildRecordList(report.hospitalVisits),
        ),

        // Medications
        ReportSectionCard(
          title: 'health_report.section_medications'.tr(),
          icon: Icons.medication,
          iconColor: const Color(0xFFFF7043),
          child: _buildRecordList(report.medications),
        ),

        // Upcoming Schedule
        ReportSectionCard(
          title: 'health_report.section_upcoming'.tr(),
          icon: Icons.schedule,
          iconColor: const Color(0xFF5C6BC0),
          child: report.upcomingReminders.isEmpty
              ? Text(
                  'health_report.no_upcoming'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.upcomingReminders.map((r) {
                    final title = r['title'] as String;
                    final scheduledAt = r['scheduledAt'] as DateTime;
                    final type = r['type'] as String;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(
                            dateFmt.format(scheduledAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSummary(List<Map<String, dynamic>> weightHistory) {
    if (weightHistory.length < 2) return const SizedBox.shrink();
    final first = weightHistory.first['weight'] as double;
    final last = weightHistory.last['weight'] as double;
    final diff = last - first;

    String summary;
    Color color;
    IconData icon;
    if (diff.abs() < 0.05) {
      summary = 'health_report.weight_stable'.tr();
      color = const Color(0xFF66BB6A);
      icon = Icons.trending_flat;
    } else if (diff > 0) {
      summary = 'health_report.weight_increased'.tr(
          args: [diff.toStringAsFixed(1)]);
      color = const Color(0xFFFF9800);
      icon = Icons.trending_up;
    } else {
      summary = 'health_report.weight_decreased'.tr(
          args: [diff.abs().toStringAsFixed(1)]);
      color = const Color(0xFF42A5F5);
      icon = Icons.trending_down;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          summary,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildLabItems(Map<String, dynamic> items) {
    return items.entries.take(6).map((entry) {
      final value = entry.value is Map
          ? (entry.value as Map)['value']?.toString() ?? '-'
          : entry.value.toString();
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 1, bottom: 1),
        child: Row(
          children: [
            Text(
              entry.key,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecordList(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Text(
        'health_report.no_records'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      );
    }
    final dateFmt = DateFormat('yyyy-MM-dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: records.map((r) {
        final title = r['title'] as String;
        final date = r['date'] as DateTime;
        final content = r['content'] as String?;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Text(
                    dateFmt.format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (content != null && content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _shareReport(HealthReport report) {
    final text = HealthReportService.formatReportAsText(report);
    Share.share(text, subject: 'health_report.share_subject'.tr(args: [report.petName]));
  }
}
