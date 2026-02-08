import 'package:intl/intl.dart';

import 'package:petcare/data/models/health_report.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/data/models/lab.dart';
import 'package:petcare/data/models/reminder.dart';

/// Service that aggregates data from records, labs, and reminders
/// to produce a [HealthReport] for a given pet and time period.
class HealthReportService {
  HealthReportService._();

  /// Generate a health report by aggregating available data.
  ///
  /// [pet] - The pet to generate the report for.
  /// [records] - All records for this pet.
  /// [labs] - All lab results for this pet.
  /// [reminders] - All reminders for this pet.
  /// [startDate] / [endDate] - The period to cover.
  static HealthReport generateReport({
    required Pet pet,
    required List<Record> records,
    required List<Lab> labs,
    required List<Reminder> reminders,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Filter records within period
    final periodRecords = records.where((r) {
      return !r.at.isBefore(startDate) && !r.at.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    // Weight history from records of type 'weight' or 'health_weight'
    final weightHistory = <Map<String, dynamic>>[];
    for (final r in periodRecords) {
      if (r.type == 'weight' || r.type == 'health_weight') {
        final weight = _extractWeight(r);
        if (weight != null) {
          weightHistory.add({
            'date': r.at,
            'weight': weight,
          });
        }
      }
    }

    // Lab results within period
    final periodLabs = labs.where((l) {
      return !l.measuredAt.isBefore(startDate) && !l.measuredAt.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final recentLabResults = periodLabs.map((l) {
      return <String, dynamic>{
        'panel': l.panel,
        'measuredAt': l.measuredAt,
        'items': l.items,
      };
    }).toList();

    // Vaccination records
    final vaccinationRecords = periodRecords
        .where((r) =>
            r.type == 'vaccine' ||
            r.type == 'health_vaccine')
        .map((r) => <String, dynamic>{
              'title': r.title,
              'date': r.at,
              'content': r.content ?? '',
            })
        .toList();

    // Hospital visits
    final hospitalVisits = periodRecords
        .where((r) =>
            r.type == 'visit' ||
            r.type == 'health_visit')
        .map((r) => <String, dynamic>{
              'title': r.title,
              'date': r.at,
              'content': r.content ?? '',
            })
        .toList();

    // Medications
    final medications = periodRecords
        .where((r) =>
            r.type == 'med' ||
            r.type == 'health_med' ||
            r.type == 'food_med' ||
            r.type == 'health_supplement' ||
            r.type == 'food_supplement')
        .map((r) => <String, dynamic>{
              'title': r.title,
              'date': r.at,
              'content': r.content ?? '',
            })
        .toList();

    // Upcoming reminders (not done, scheduled after now)
    final now = DateTime.now();
    final upcomingReminders = reminders
        .where((r) => !r.done && r.scheduledAt.isAfter(now))
        .map((r) => <String, dynamic>{
              'title': r.title,
              'scheduledAt': r.scheduledAt,
              'type': r.type,
              'note': r.note ?? '',
            })
        .toList()
      ..sort((a, b) =>
          (a['scheduledAt'] as DateTime).compareTo(b['scheduledAt'] as DateTime));

    return HealthReport(
      petName: pet.name,
      species: pet.species,
      breed: pet.breed,
      weightKg: pet.weightKg,
      periodStart: startDate,
      periodEnd: endDate,
      weightHistory: weightHistory,
      recentLabResults: recentLabResults,
      vaccinationRecords: vaccinationRecords,
      hospitalVisits: hospitalVisits,
      medications: medications,
      upcomingReminders: upcomingReminders,
    );
  }

  /// Format the report as a shareable plain-text string.
  static String formatReportAsText(HealthReport report) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer();

    // Header
    buffer.writeln('============================');
    buffer.writeln('  Pet Health Report');
    buffer.writeln('============================');
    buffer.writeln();

    // Basic Info
    buffer.writeln('[ Basic Info ]');
    buffer.writeln('Name: ${report.petName}');
    buffer.writeln('Species: ${report.species}');
    if (report.breed != null && report.breed!.isNotEmpty) {
      buffer.writeln('Breed: ${report.breed}');
    }
    if (report.weightKg != null) {
      buffer.writeln('Current Weight: ${report.weightKg!.toStringAsFixed(1)} kg');
    }
    buffer.writeln(
        'Period: ${dateFmt.format(report.periodStart)} ~ ${dateFmt.format(report.periodEnd)}');
    buffer.writeln();

    // Weight Trend
    buffer.writeln('[ Weight Trend ]');
    if (report.weightHistory.isEmpty) {
      buffer.writeln('No weight records in this period.');
    } else {
      for (final entry in report.weightHistory) {
        final date = entry['date'] as DateTime;
        final weight = entry['weight'] as double;
        buffer.writeln(
            '  ${dateFmt.format(date)}: ${weight.toStringAsFixed(1)} kg');
      }
      final first = report.weightHistory.first['weight'] as double;
      final last = report.weightHistory.last['weight'] as double;
      final diff = last - first;
      if (diff.abs() < 0.05) {
        buffer.writeln('  -> Stable');
      } else if (diff > 0) {
        buffer.writeln('  -> Increased by ${diff.toStringAsFixed(1)} kg');
      } else {
        buffer.writeln('  -> Decreased by ${diff.abs().toStringAsFixed(1)} kg');
      }
    }
    buffer.writeln();

    // Lab Results
    buffer.writeln('[ Lab Results ]');
    if (report.recentLabResults.isEmpty) {
      buffer.writeln('No lab results in this period.');
    } else {
      for (final lab in report.recentLabResults) {
        final measuredAt = lab['measuredAt'] as DateTime;
        final panel = lab['panel'] as String;
        buffer.writeln('  $panel (${dateFmt.format(measuredAt)})');
        final items = lab['items'] as Map<String, dynamic>;
        for (final entry in items.entries) {
          final itemData = entry.value;
          if (itemData is Map<String, dynamic>) {
            final value = itemData['value'] ?? '-';
            buffer.writeln('    ${entry.key}: $value');
          } else {
            buffer.writeln('    ${entry.key}: $itemData');
          }
        }
      }
    }
    buffer.writeln();

    // Vaccinations
    buffer.writeln('[ Vaccinations ]');
    if (report.vaccinationRecords.isEmpty) {
      buffer.writeln('No vaccinations in this period.');
    } else {
      for (final v in report.vaccinationRecords) {
        final date = v['date'] as DateTime;
        final title = v['title'] as String;
        buffer.writeln('  ${dateFmt.format(date)}: $title');
        final content = v['content'] as String?;
        if (content != null && content.isNotEmpty) {
          buffer.writeln('    $content');
        }
      }
    }
    buffer.writeln();

    // Hospital Visits
    buffer.writeln('[ Hospital Visits ]');
    if (report.hospitalVisits.isEmpty) {
      buffer.writeln('No hospital visits in this period.');
    } else {
      for (final v in report.hospitalVisits) {
        final date = v['date'] as DateTime;
        final title = v['title'] as String;
        buffer.writeln('  ${dateFmt.format(date)}: $title');
        final content = v['content'] as String?;
        if (content != null && content.isNotEmpty) {
          buffer.writeln('    $content');
        }
      }
    }
    buffer.writeln();

    // Medications
    buffer.writeln('[ Medications ]');
    if (report.medications.isEmpty) {
      buffer.writeln('No medication records in this period.');
    } else {
      for (final m in report.medications) {
        final date = m['date'] as DateTime;
        final title = m['title'] as String;
        buffer.writeln('  ${dateFmt.format(date)}: $title');
        final content = m['content'] as String?;
        if (content != null && content.isNotEmpty) {
          buffer.writeln('    $content');
        }
      }
    }
    buffer.writeln();

    // Upcoming Schedule
    buffer.writeln('[ Upcoming Schedule ]');
    if (report.upcomingReminders.isEmpty) {
      buffer.writeln('No upcoming reminders.');
    } else {
      for (final r in report.upcomingReminders) {
        final scheduledAt = r['scheduledAt'] as DateTime;
        final title = r['title'] as String;
        final type = r['type'] as String;
        buffer.writeln(
            '  ${dateTimeFmt.format(scheduledAt)} [$type] $title');
        final note = r['note'] as String?;
        if (note != null && note.isNotEmpty) {
          buffer.writeln('    $note');
        }
      }
    }
    buffer.writeln();

    buffer.writeln('---');
    buffer.writeln('Generated by PetCare App');

    return buffer.toString();
  }

  /// Try to extract a numeric weight value from a Record.
  static double? _extractWeight(Record record) {
    // Try from value map
    if (record.value != null) {
      final v = record.value!;
      if (v.containsKey('weight')) {
        final w = v['weight'];
        if (w is num) return w.toDouble();
        if (w is String) return double.tryParse(w);
      }
      if (v.containsKey('weight_kg')) {
        final w = v['weight_kg'];
        if (w is num) return w.toDouble();
        if (w is String) return double.tryParse(w);
      }
    }
    // Try from content
    if (record.content != null && record.content!.isNotEmpty) {
      return double.tryParse(record.content!.replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    return null;
  }
}
