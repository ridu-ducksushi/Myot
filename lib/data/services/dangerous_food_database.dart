/// Static database of foods that are dangerous or toxic to pets.
/// Each entry includes multilingual names, severity level, and symptoms.
class DangerousFoodDatabase {
  DangerousFoodDatabase._();

  static const List<DangerousFood> foods = [
    // Critical severity
    DangerousFood(
      nameKo: '초콜릿',
      nameEn: 'Chocolate',
      nameJa: 'チョコレート',
      severity: 'critical',
      symptoms: ['vomiting', 'diarrhea', 'rapid_breathing', 'seizures', 'heart_failure'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '포도/건포도',
      nameEn: 'Grapes / Raisins',
      nameJa: 'ブドウ/レーズン',
      severity: 'critical',
      symptoms: ['vomiting', 'lethargy', 'kidney_failure'],
      affectedSpecies: ['dog'],
    ),
    DangerousFood(
      nameKo: '자일리톨',
      nameEn: 'Xylitol',
      nameJa: 'キシリトール',
      severity: 'critical',
      symptoms: ['vomiting', 'hypoglycemia', 'seizures', 'liver_failure'],
      affectedSpecies: ['dog'],
    ),
    DangerousFood(
      nameKo: '양파/파',
      nameEn: 'Onions / Leeks',
      nameJa: '玉ねぎ/ネギ',
      severity: 'critical',
      symptoms: ['vomiting', 'diarrhea', 'anemia', 'lethargy'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '마늘',
      nameEn: 'Garlic',
      nameJa: 'ニンニク',
      severity: 'critical',
      symptoms: ['vomiting', 'diarrhea', 'anemia', 'weakness'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '마카다미아 너트',
      nameEn: 'Macadamia Nuts',
      nameJa: 'マカダミアナッツ',
      severity: 'critical',
      symptoms: ['weakness', 'vomiting', 'tremors', 'hyperthermia'],
      affectedSpecies: ['dog'],
    ),
    DangerousFood(
      nameKo: '알코올',
      nameEn: 'Alcohol',
      nameJa: 'アルコール',
      severity: 'critical',
      symptoms: ['vomiting', 'diarrhea', 'difficulty_breathing', 'coma'],
      affectedSpecies: ['dog', 'cat'],
    ),

    // High severity
    DangerousFood(
      nameKo: '카페인',
      nameEn: 'Caffeine',
      nameJa: 'カフェイン',
      severity: 'high',
      symptoms: ['restlessness', 'rapid_breathing', 'heart_palpitations', 'tremors'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '아보카도',
      nameEn: 'Avocado',
      nameJa: 'アボカド',
      severity: 'high',
      symptoms: ['vomiting', 'diarrhea', 'breathing_difficulty'],
      affectedSpecies: ['dog', 'cat', 'bird'],
    ),
    DangerousFood(
      nameKo: '날 반죽/이스트',
      nameEn: 'Raw Yeast Dough',
      nameJa: '生イースト生地',
      severity: 'high',
      symptoms: ['bloating', 'vomiting', 'disorientation'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '자두/복숭아/체리 씨',
      nameEn: 'Stone Fruit Pits',
      nameJa: '果物の種',
      severity: 'high',
      symptoms: ['vomiting', 'diarrhea', 'cyanide_toxicity', 'intestinal_blockage'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '호두',
      nameEn: 'Walnuts',
      nameJa: 'クルミ',
      severity: 'high',
      symptoms: ['vomiting', 'tremors', 'seizures'],
      affectedSpecies: ['dog'],
    ),

    // Moderate severity
    DangerousFood(
      nameKo: '우유/유제품',
      nameEn: 'Milk / Dairy',
      nameJa: '牛乳/乳製品',
      severity: 'moderate',
      symptoms: ['diarrhea', 'vomiting', 'gas'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '날계란',
      nameEn: 'Raw Eggs',
      nameJa: '生卵',
      severity: 'moderate',
      symptoms: ['vomiting', 'diarrhea', 'biotin_deficiency'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '날생선',
      nameEn: 'Raw Fish',
      nameJa: '生魚',
      severity: 'moderate',
      symptoms: ['vomiting', 'fever', 'thiamine_deficiency'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '소금 (과다)',
      nameEn: 'Excessive Salt',
      nameJa: '塩分(過剰)',
      severity: 'moderate',
      symptoms: ['vomiting', 'diarrhea', 'tremors', 'excessive_thirst'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '감',
      nameEn: 'Persimmon',
      nameJa: '柿',
      severity: 'moderate',
      symptoms: ['vomiting', 'diarrhea', 'intestinal_blockage'],
      affectedSpecies: ['dog'],
    ),
    DangerousFood(
      nameKo: '날 뼈',
      nameEn: 'Cooked Bones',
      nameJa: '加熱した骨',
      severity: 'moderate',
      symptoms: ['choking', 'intestinal_puncture', 'constipation'],
      affectedSpecies: ['dog', 'cat'],
    ),
    DangerousFood(
      nameKo: '옥수수 속대',
      nameEn: 'Corn Cob',
      nameJa: 'トウモロコシの芯',
      severity: 'moderate',
      symptoms: ['intestinal_blockage', 'vomiting'],
      affectedSpecies: ['dog'],
    ),
    DangerousFood(
      nameKo: '부추',
      nameEn: 'Chives',
      nameJa: 'ニラ',
      severity: 'high',
      symptoms: ['vomiting', 'diarrhea', 'anemia'],
      affectedSpecies: ['dog', 'cat'],
    ),
  ];

  /// Search foods by name across all supported languages.
  static List<DangerousFood> search(String query) {
    if (query.trim().isEmpty) return foods;
    final lowerQuery = query.toLowerCase();
    return foods.where((food) {
      return food.nameKo.toLowerCase().contains(lowerQuery) ||
          food.nameEn.toLowerCase().contains(lowerQuery) ||
          food.nameJa.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter foods by severity level.
  static List<DangerousFood> filterBySeverity(String severity) {
    return foods.where((food) => food.severity == severity).toList();
  }

  /// Filter foods by affected species.
  static List<DangerousFood> filterBySpecies(String species) {
    return foods
        .where((food) => food.affectedSpecies.contains(species.toLowerCase()))
        .toList();
  }
}

/// Represents a single dangerous food entry.
class DangerousFood {
  const DangerousFood({
    required this.nameKo,
    required this.nameEn,
    required this.nameJa,
    required this.severity,
    required this.symptoms,
    required this.affectedSpecies,
  });

  final String nameKo;
  final String nameEn;
  final String nameJa;
  final String severity; // critical|high|moderate
  final List<String> symptoms;
  final List<String> affectedSpecies;

  /// Returns the localized name based on language code.
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return nameKo;
      case 'ja':
        return nameJa;
      default:
        return nameEn;
    }
  }
}
