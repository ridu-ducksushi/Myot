import 'dart:math' as math;

/// 사료 급여량 계산 서비스
/// RER = 70 × (체중kg ^ 0.75)
/// DER = RER × 활동 계수
class FoodCalculatorService {
  /// RER (Resting Energy Requirement) 계산
  static double calculateRER(double weightKg) {
    if (weightKg <= 0) return 0;
    return 70 * math.pow(weightKg, 0.75).toDouble();
  }

  /// DER (Daily Energy Requirement) 계산
  static double calculateDER({
    required double weightKg,
    required String species,
    required String ageCategory,
    required bool isNeutered,
    required String activityLevel,
  }) {
    final rer = calculateRER(weightKg);
    final factor = getActivityFactor(
      species: species,
      ageCategory: ageCategory,
      isNeutered: isNeutered,
      activityLevel: activityLevel,
    );
    return rer * factor;
  }

  /// 일일 급여량 (g) 계산
  static double calculateDailyPortion({
    required double derKcal,
    required double foodKcalPer100g,
  }) {
    if (foodKcalPer100g <= 0) return 0;
    return (derKcal / foodKcalPer100g) * 100;
  }

  /// 나이 카테고리 결정
  static String getAgeCategory({
    required String species,
    required int ageMonths,
  }) {
    if (species.toLowerCase() == 'dog') {
      if (ageMonths < 4) return 'puppy_young';
      if (ageMonths < 12) return 'puppy';
      if (ageMonths < 84) return 'adult';
      return 'senior';
    } else {
      if (ageMonths < 4) return 'kitten_young';
      if (ageMonths < 12) return 'kitten';
      if (ageMonths < 84) return 'adult';
      return 'senior';
    }
  }

  /// 활동 계수 반환
  static double getActivityFactor({
    required String species,
    required String ageCategory,
    required bool isNeutered,
    required String activityLevel,
  }) {
    if (species.toLowerCase() == 'dog') {
      return _dogFactor(ageCategory, isNeutered, activityLevel);
    }
    return _catFactor(ageCategory, isNeutered, activityLevel);
  }

  static double _dogFactor(
      String ageCategory, bool isNeutered, String activityLevel) {
    switch (ageCategory) {
      case 'puppy_young':
        return 3.0;
      case 'puppy':
        return 2.0;
      case 'senior':
        return isNeutered ? 1.2 : 1.4;
      default:
        if (isNeutered) {
          switch (activityLevel) {
            case 'low':
              return 1.2;
            case 'high':
              return 1.8;
            default:
              return 1.6;
          }
        } else {
          switch (activityLevel) {
            case 'low':
              return 1.4;
            case 'high':
              return 2.0;
            default:
              return 1.8;
          }
        }
    }
  }

  static double _catFactor(
      String ageCategory, bool isNeutered, String activityLevel) {
    switch (ageCategory) {
      case 'kitten_young':
        return 2.5;
      case 'kitten':
        return 2.0;
      case 'senior':
        return isNeutered ? 1.1 : 1.2;
      default:
        if (isNeutered) {
          switch (activityLevel) {
            case 'low':
              return 1.0;
            case 'high':
              return 1.4;
            default:
              return 1.2;
          }
        } else {
          switch (activityLevel) {
            case 'low':
              return 1.2;
            case 'high':
              return 1.6;
            default:
              return 1.4;
          }
        }
    }
  }
}
