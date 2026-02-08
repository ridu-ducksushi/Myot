import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/data/services/breed_weight_database.dart';

/// Data class holding weight guide information for a pet.
class WeightGuideData {
  const WeightGuideData({
    required this.petName,
    required this.species,
    this.breed,
    this.currentWeightKg,
    this.breedRange,
    this.weightStatus,
    this.trend,
    this.recentWeights = const [],
  });

  final String petName;
  final String species;
  final String? breed;
  final double? currentWeightKg;
  final BreedWeightRange? breedRange;

  /// One of: 'underweight', 'normal', 'overweight', 'obese', 'unknown'.
  final String? weightStatus;

  /// One of: 'increasing', 'decreasing', 'stable', 'unknown'.
  final String? trend;

  /// Recent weight entries sorted by date ascending.
  /// Each entry: {'id': String, 'date': DateTime, 'weight': double, 'note': String?}.
  final List<Map<String, dynamic>> recentWeights;
}

/// Provider for weight guide data for a specific pet.
final weightGuideProvider = Provider.family<WeightGuideData, String>(
  (ref, petId) {
    final pet = ref.watch(petByIdProvider(petId));
    if (pet == null) {
      return const WeightGuideData(
        petName: '',
        species: '',
        weightStatus: 'unknown',
        trend: 'unknown',
      );
    }

    // Find breed range
    BreedWeightRange? breedRange;
    if (pet.breed != null && pet.breed!.isNotEmpty) {
      breedRange = BreedWeightDatabase.findBreed(pet.breed!);
    }

    // Get recent weight records
    final records = ref.watch(recordsForPetProvider(petId));
    final weightRecords = records
        .where((r) =>
            r.type == 'weight' ||
            r.type == 'health_weight')
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    final recentWeights = <Map<String, dynamic>>[];
    for (final r in weightRecords) {
      double? weight;
      if (r.value != null) {
        final v = r.value!;
        if (v.containsKey('weight')) {
          final w = v['weight'];
          if (w is num) weight = w.toDouble();
          if (w is String) weight = double.tryParse(w);
        } else if (v.containsKey('weight_kg')) {
          final w = v['weight_kg'];
          if (w is num) weight = w.toDouble();
          if (w is String) weight = double.tryParse(w);
        }
      }
      if (weight == null && r.content != null && r.content!.isNotEmpty) {
        weight = double.tryParse(r.content!.replaceAll(RegExp(r'[^0-9.]'), ''));
      }
      if (weight != null) {
        recentWeights.add({
          'id': r.id,
          'date': r.at,
          'weight': weight,
          'note': r.content,
        });
      }
    }

    // Determine current weight: latest record or pet profile
    final currentWeight = recentWeights.isNotEmpty
        ? recentWeights.last['weight'] as double
        : pet.weightKg;

    // Evaluate weight status
    String? weightStatus;
    if (currentWeight != null && breedRange != null) {
      weightStatus = BreedWeightDatabase.evaluateWeightStatus(
        currentWeightKg: currentWeight,
        range: breedRange,
      );
    } else {
      weightStatus = 'unknown';
    }

    // Calculate trend from last N weights
    String trend = 'unknown';
    if (recentWeights.length >= 2) {
      final last3 = recentWeights.length > 3
          ? recentWeights.sublist(recentWeights.length - 3)
          : recentWeights;
      final firstW = last3.first['weight'] as double;
      final lastW = last3.last['weight'] as double;
      final diff = lastW - firstW;
      final percentChange = firstW > 0 ? (diff / firstW).abs() : 0.0;

      if (percentChange < 0.02) {
        trend = 'stable';
      } else if (diff > 0) {
        trend = 'increasing';
      } else {
        trend = 'decreasing';
      }
    } else if (recentWeights.length == 1) {
      trend = 'stable';
    }

    return WeightGuideData(
      petName: pet.name,
      species: pet.species,
      breed: pet.breed,
      currentWeightKg: currentWeight,
      breedRange: breedRange,
      weightStatus: weightStatus,
      trend: trend,
      recentWeights: recentWeights,
    );
  },
);
