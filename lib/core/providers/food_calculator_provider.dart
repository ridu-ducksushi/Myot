import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for food calculator inputs and outputs
class FoodCalculatorState {
  const FoodCalculatorState({
    this.weightKg = 0.0,
    this.species = 'Dog',
    this.ageCategory = 'adult',
    this.isNeutered = false,
    this.activityLevel = 'normal',
    this.foodKcalPer100g,
    this.rer = 0.0,
    this.der = 0.0,
    this.dailyPortionGrams,
  });

  final double weightKg;
  final String species;
  final String ageCategory;
  final bool isNeutered;
  final String activityLevel;
  final double? foodKcalPer100g;
  final double rer;
  final double der;
  final double? dailyPortionGrams;

  FoodCalculatorState copyWith({
    double? weightKg,
    String? species,
    String? ageCategory,
    bool? isNeutered,
    String? activityLevel,
    double? foodKcalPer100g,
    bool clearFoodKcal = false,
    double? rer,
    double? der,
    double? dailyPortionGrams,
    bool clearDailyPortion = false,
  }) {
    return FoodCalculatorState(
      weightKg: weightKg ?? this.weightKg,
      species: species ?? this.species,
      ageCategory: ageCategory ?? this.ageCategory,
      isNeutered: isNeutered ?? this.isNeutered,
      activityLevel: activityLevel ?? this.activityLevel,
      foodKcalPer100g:
          clearFoodKcal ? null : (foodKcalPer100g ?? this.foodKcalPer100g),
      rer: rer ?? this.rer,
      der: der ?? this.der,
      dailyPortionGrams: clearDailyPortion
          ? null
          : (dailyPortionGrams ?? this.dailyPortionGrams),
    );
  }
}

/// Food calculator state provider
final foodCalculatorProvider =
    StateProvider<FoodCalculatorState>((ref) => const FoodCalculatorState());
