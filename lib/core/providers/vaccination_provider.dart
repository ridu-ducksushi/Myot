import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/services/vaccination_schedule_service.dart';

/// Completed vaccine keys for a specific pet.
/// Reads all records of type 'health_vaccine' and extracts the vaccine key from the value map.
final completedVaccineKeysProvider =
    Provider.family<Set<String>, String>((ref, petId) {
  final records = ref.watch(recordsForPetProvider(petId));
  final vaccineRecords =
      records.where((r) => r.type == 'health_vaccine').toList();
  final keys = <String>{};
  for (final record in vaccineRecords) {
    final value = record.value;
    if (value != null && value['vaccineKey'] is String) {
      keys.add(value['vaccineKey'] as String);
    }
  }
  return keys;
});

/// Full vaccination schedule for a specific pet.
/// Returns empty list if species is not supported or birthDate is null.
final vaccinationScheduleProvider =
    Provider.family<List<VaccineItem>, String>((ref, petId) {
  final pet = ref.watch(petByIdProvider(petId));
  if (pet == null) return [];
  if (pet.birthDate == null) return [];
  if (!VaccinationScheduleService.isSpeciesSupported(pet.species)) return [];

  final completedKeys = ref.watch(completedVaccineKeysProvider(petId));
  return VaccinationScheduleService.generateSchedule(
    species: pet.species,
    birthDate: pet.birthDate!,
    completedVaccineKeys: completedKeys,
  );
});

/// Overdue vaccines for a specific pet
final overdueVaccinesProvider =
    Provider.family<List<VaccineItem>, String>((ref, petId) {
  final schedule = ref.watch(vaccinationScheduleProvider(petId));
  return schedule.where((item) => item.status == 'overdue').toList();
});

/// Upcoming vaccines for a specific pet
final upcomingVaccinesProvider =
    Provider.family<List<VaccineItem>, String>((ref, petId) {
  final schedule = ref.watch(vaccinationScheduleProvider(petId));
  return schedule.where((item) => item.status == 'upcoming').toList();
});

/// Completed vaccines for a specific pet
final completedVaccinesProvider =
    Provider.family<List<VaccineItem>, String>((ref, petId) {
  final schedule = ref.watch(vaccinationScheduleProvider(petId));
  return schedule.where((item) => item.status == 'completed').toList();
});
