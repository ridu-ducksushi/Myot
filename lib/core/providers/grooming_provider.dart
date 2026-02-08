import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/models/record.dart';

/// Grooming records for a specific pet (filtered from records provider)
final groomingRecordsForPetProvider =
    Provider.family<List<Record>, String>((ref, petId) {
  final records = ref.watch(recordsForPetProvider(petId));
  return records.where((record) => record.type == 'grooming').toList();
});

/// Grooming records filtered by subType for a specific pet
final groomingBySubTypeProvider =
    Provider.family<List<Record>, ({String petId, String subType})>(
        (ref, params) {
  final groomingRecords = ref.watch(groomingRecordsForPetProvider(params.petId));
  return groomingRecords.where((record) {
    final value = record.value;
    if (value == null) return false;
    return value['subType'] == params.subType;
  }).toList();
});

/// Last grooming date for a specific subType
final lastGroomingDateProvider =
    Provider.family<DateTime?, ({String petId, String subType})>(
        (ref, params) {
  final records = ref.watch(
      groomingBySubTypeProvider((petId: params.petId, subType: params.subType)));
  if (records.isEmpty) return null;
  // Records are already sorted by date descending from the recordsProvider
  return records.first.at;
});

/// Next due date for a specific subType (from value map)
final nextGroomingDueDateProvider =
    Provider.family<DateTime?, ({String petId, String subType})>(
        (ref, params) {
  final records = ref.watch(
      groomingBySubTypeProvider((petId: params.petId, subType: params.subType)));
  if (records.isEmpty) return null;
  final latestRecord = records.first;
  final value = latestRecord.value;
  if (value == null) return null;
  final nextDueDateStr = value['nextDueDate'] as String?;
  if (nextDueDateStr == null) return null;
  return DateTime.tryParse(nextDueDateStr);
});

/// All grooming subTypes
const groomingSubTypes = [
  'bath',
  'nail_trim',
  'ear_clean',
  'teeth_brush',
  'haircut',
];
