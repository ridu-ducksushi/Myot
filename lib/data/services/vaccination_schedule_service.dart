/// Vaccination schedule service with static vaccine databases for dogs and cats.
/// Generates recommended vaccination schedules based on species and birth date.
class VaccinationScheduleService {
  /// Dog vaccine database: name, age in weeks for first dose, booster intervals
  static const List<Map<String, dynamic>> _dogVaccines = [
    {
      'name': 'DHPP (Distemper/Hepatitis/Parainfluenza/Parvovirus)',
      'shortName': 'DHPP',
      'firstDoseWeeks': 6,
      'boosterWeeks': [10, 14, 18],
      'annualBooster': true,
    },
    {
      'name': 'Rabies',
      'shortName': 'Rabies',
      'firstDoseWeeks': 12,
      'boosterWeeks': <int>[],
      'annualBooster': true,
    },
    {
      'name': 'Bordetella (Kennel Cough)',
      'shortName': 'Bordetella',
      'firstDoseWeeks': 8,
      'boosterWeeks': <int>[],
      'annualBooster': true,
    },
    {
      'name': 'Leptospirosis',
      'shortName': 'Leptospirosis',
      'firstDoseWeeks': 12,
      'boosterWeeks': [16],
      'annualBooster': true,
    },
    {
      'name': 'Canine Influenza (H3N2/H3N8)',
      'shortName': 'Canine Influenza',
      'firstDoseWeeks': 12,
      'boosterWeeks': [16],
      'annualBooster': true,
    },
    {
      'name': 'Lyme Disease',
      'shortName': 'Lyme',
      'firstDoseWeeks': 12,
      'boosterWeeks': [16],
      'annualBooster': true,
    },
  ];

  /// Cat vaccine database
  static const List<Map<String, dynamic>> _catVaccines = [
    {
      'name': 'FVRCP (Feline Viral Rhinotracheitis/Calicivirus/Panleukopenia)',
      'shortName': 'FVRCP',
      'firstDoseWeeks': 6,
      'boosterWeeks': [10, 14],
      'annualBooster': true,
    },
    {
      'name': 'Rabies',
      'shortName': 'Rabies',
      'firstDoseWeeks': 12,
      'boosterWeeks': <int>[],
      'annualBooster': true,
    },
    {
      'name': 'FeLV (Feline Leukemia Virus)',
      'shortName': 'FeLV',
      'firstDoseWeeks': 8,
      'boosterWeeks': [12],
      'annualBooster': true,
    },
    {
      'name': 'FIV (Feline Immunodeficiency Virus)',
      'shortName': 'FIV',
      'firstDoseWeeks': 8,
      'boosterWeeks': [11, 14],
      'annualBooster': false,
    },
    {
      'name': 'Bordetella',
      'shortName': 'Bordetella',
      'firstDoseWeeks': 8,
      'boosterWeeks': <int>[],
      'annualBooster': true,
    },
    {
      'name': 'Chlamydia',
      'shortName': 'Chlamydia',
      'firstDoseWeeks': 9,
      'boosterWeeks': [12],
      'annualBooster': true,
    },
  ];

  /// Generate a vaccination schedule based on species and birth date.
  /// [completedVaccineKeys] is a set of "shortName_dueDate" strings that have been completed.
  static List<VaccineItem> generateSchedule({
    required String species,
    required DateTime birthDate,
    Set<String> completedVaccineKeys = const {},
  }) {
    final vaccines = _getVaccinesForSpecies(species);
    if (vaccines.isEmpty) return [];

    final now = DateTime.now();
    final items = <VaccineItem>[];

    for (final vaccine in vaccines) {
      final shortName = vaccine['shortName'] as String;
      final fullName = vaccine['name'] as String;
      final firstDoseWeeks = vaccine['firstDoseWeeks'] as int;
      final boosterWeeks = vaccine['boosterWeeks'] as List<int>;
      final annualBooster = vaccine['annualBooster'] as bool;

      // First dose
      final firstDoseDate =
          birthDate.add(Duration(days: firstDoseWeeks * 7));
      items.add(_createVaccineItem(
        name: '$shortName - 1st Dose',
        fullName: fullName,
        dueDate: firstDoseDate,
        now: now,
        completedKeys: completedVaccineKeys,
      ));

      // Booster doses
      for (var i = 0; i < boosterWeeks.length; i++) {
        final boosterDate =
            birthDate.add(Duration(days: boosterWeeks[i] * 7));
        items.add(_createVaccineItem(
          name: '$shortName - Booster ${i + 2}',
          fullName: fullName,
          dueDate: boosterDate,
          now: now,
          completedKeys: completedVaccineKeys,
        ));
      }

      // Annual boosters (generate for next 3 years from birth)
      if (annualBooster) {
        final lastInitialWeek = boosterWeeks.isNotEmpty
            ? boosterWeeks.last
            : firstDoseWeeks;
        final firstAnnualDate =
            birthDate.add(Duration(days: lastInitialWeek * 7 + 365));

        for (var year = 0; year < 3; year++) {
          final annualDate =
              firstAnnualDate.add(Duration(days: 365 * year));
          // Only include if within a reasonable future window
          if (annualDate.isBefore(now.add(const Duration(days: 730)))) {
            items.add(_createVaccineItem(
              name: '$shortName - Annual',
              fullName: fullName,
              dueDate: annualDate,
              now: now,
              completedKeys: completedVaccineKeys,
            ));
          }
        }
      }
    }

    // Sort: overdue first, then upcoming, then completed
    items.sort((a, b) {
      const statusOrder = {'overdue': 0, 'upcoming': 1, 'completed': 2};
      final statusCompare =
          (statusOrder[a.status] ?? 1).compareTo(statusOrder[b.status] ?? 1);
      if (statusCompare != 0) return statusCompare;
      return a.dueDate.compareTo(b.dueDate);
    });

    return items;
  }

  static List<Map<String, dynamic>> _getVaccinesForSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return _dogVaccines;
      case 'cat':
        return _catVaccines;
      default:
        return [];
    }
  }

  static VaccineItem _createVaccineItem({
    required String name,
    required String fullName,
    required DateTime dueDate,
    required DateTime now,
    required Set<String> completedKeys,
  }) {
    final key = '${name}_${dueDate.toIso8601String().split('T').first}';
    final isCompleted = completedKeys.contains(key);

    String status;
    if (isCompleted) {
      status = 'completed';
    } else if (dueDate.isBefore(now)) {
      status = 'overdue';
    } else {
      status = 'upcoming';
    }

    return VaccineItem(
      name: name,
      fullName: fullName,
      dueDate: dueDate,
      status: status,
      key: key,
    );
  }

  /// Check if the given species is supported for vaccination schedules.
  static bool isSpeciesSupported(String species) {
    final lower = species.toLowerCase();
    return lower == 'dog' || lower == 'cat';
  }
}

/// Represents a single vaccine item in the schedule.
class VaccineItem {
  const VaccineItem({
    required this.name,
    required this.fullName,
    required this.dueDate,
    required this.status,
    required this.key,
  });

  final String name;
  final String fullName;
  final DateTime dueDate;
  final String status; // overdue|upcoming|completed
  final String key; // unique key for completion tracking
}
