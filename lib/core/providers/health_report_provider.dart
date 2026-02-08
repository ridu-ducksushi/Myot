import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/core/providers/reminders_provider.dart';
import 'package:petcare/data/models/health_report.dart';
import 'package:petcare/data/models/lab.dart';
import 'package:petcare/data/services/health_report_service.dart';

/// Parameters for generating a health report.
class HealthReportParams {
  const HealthReportParams({
    required this.petId,
    required this.startDate,
    required this.endDate,
  });

  final String petId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthReportParams &&
          petId == other.petId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(petId, startDate, endDate);
}

/// FutureProvider that generates a [HealthReport] for the given parameters.
///
/// Aggregates pet info, records, labs, and reminders into a single report.
final healthReportProvider =
    FutureProvider.family<HealthReport?, HealthReportParams>(
  (ref, params) async {
    final pet = ref.watch(petByIdProvider(params.petId));
    if (pet == null) return null;

    final records = ref.watch(recordsForPetProvider(params.petId));
    final reminders = ref.watch(remindersForPetProvider(params.petId));

    // Labs are not currently provided via a dedicated provider,
    // so we pass an empty list. When a labs provider is available,
    // wire it here.
    final List<Lab> labs = [];

    return HealthReportService.generateReport(
      pet: pet,
      records: records,
      labs: labs,
      reminders: reminders,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  },
);
