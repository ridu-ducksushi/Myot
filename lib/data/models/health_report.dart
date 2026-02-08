/// Health report data class (non-freezed, not persisted).
///
/// Aggregates pet health information for a given period
/// to generate a shareable health summary.
class HealthReport {
  HealthReport({
    required this.petName,
    required this.species,
    this.breed,
    this.weightKg,
    required this.periodStart,
    required this.periodEnd,
    this.weightHistory = const [],
    this.recentLabResults = const [],
    this.vaccinationRecords = const [],
    this.hospitalVisits = const [],
    this.medications = const [],
    this.upcomingReminders = const [],
  });

  final String petName;
  final String species;
  final String? breed;
  final double? weightKg;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// List of weight entries: each map has 'date' (DateTime) and 'weight' (double).
  final List<Map<String, dynamic>> weightHistory;

  /// Recent lab results: each map has 'panel' (String), 'measuredAt' (DateTime),
  /// and 'items' (Map<String, dynamic>).
  final List<Map<String, dynamic>> recentLabResults;

  /// Vaccination records: each map has 'title' (String), 'date' (DateTime),
  /// and optional 'content' (String).
  final List<Map<String, dynamic>> vaccinationRecords;

  /// Hospital visit records: each map has 'title' (String), 'date' (DateTime),
  /// and optional 'content' (String).
  final List<Map<String, dynamic>> hospitalVisits;

  /// Medication records: each map has 'title' (String), 'date' (DateTime),
  /// and optional 'content' (String).
  final List<Map<String, dynamic>> medications;

  /// Upcoming reminders: each map has 'title' (String), 'scheduledAt' (DateTime),
  /// 'type' (String), and optional 'note' (String).
  final List<Map<String, dynamic>> upcomingReminders;

  HealthReport copyWith({
    String? petName,
    String? species,
    String? breed,
    double? weightKg,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<Map<String, dynamic>>? weightHistory,
    List<Map<String, dynamic>>? recentLabResults,
    List<Map<String, dynamic>>? vaccinationRecords,
    List<Map<String, dynamic>>? hospitalVisits,
    List<Map<String, dynamic>>? medications,
    List<Map<String, dynamic>>? upcomingReminders,
  }) {
    return HealthReport(
      petName: petName ?? this.petName,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      weightKg: weightKg ?? this.weightKg,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      weightHistory: weightHistory ?? this.weightHistory,
      recentLabResults: recentLabResults ?? this.recentLabResults,
      vaccinationRecords: vaccinationRecords ?? this.vaccinationRecords,
      hospitalVisits: hospitalVisits ?? this.hospitalVisits,
      medications: medications ?? this.medications,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
    );
  }
}
