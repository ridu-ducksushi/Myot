import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 레코드 타입에 대한 아이콘/라벨/카테고리 유틸리티
/// 단일 진실의 원천 - 모든 레코드 관련 매핑은 이 클래스에서 관리
class RecordUtils {
  /// 상세 레코드 타입(food_meal 등)에 대한 아이콘 반환
  static IconData getIconForType(String type) {
    switch (type) {
      case 'food_meal':
        return Icons.dinner_dining;
      case 'food_snack':
        return Icons.cookie;
      case 'food_water':
        return Icons.water_drop;
      case 'food_med':
        return Icons.medical_services;
      case 'food_supplement':
        return Icons.medication;
      case 'health_supplement':
        return Icons.medication;
      case 'health_vaccine':
        return Icons.vaccines;
      case 'health_visit':
        return Icons.local_hospital;
      case 'health_weight':
        return Icons.more_horiz;
      case 'health_symptom':
        return Icons.medical_information;
      case 'activity_play':
        return Icons.gamepad_outlined;
      case 'activity_explore':
        return Icons.explore_outlined;
      case 'activity_outing':
        return Icons.directions_walk;
      case 'activity_walk':
        return Icons.directions_walk;
      case 'activity_rest':
        return Icons.hotel_outlined;
      case 'activity_other':
        return Icons.more_horiz;
      case 'poop_urine':
        return Icons.opacity;
      case 'poop_feces':
        return Icons.pets;
      case 'hygiene_brush':
        return Icons.brush;
      case 'poop_other':
        return Icons.more_horiz;
      case 'grooming':
        return Icons.content_cut;
      default:
        return Icons.add_circle_outline;
    }
  }

  /// 간단한 레코드 타입(meal, snack 등)에 대한 아이콘 반환
  static IconData getIconForSimpleType(String type) {
    switch (type.toLowerCase()) {
      case 'meal':
        return Icons.restaurant;
      case 'snack':
        return Icons.cookie;
      case 'med':
      case 'medicine':
        return Icons.medical_services;
      case 'vaccine':
        return Icons.vaccines;
      case 'visit':
        return Icons.local_hospital;
      case 'weight':
        return Icons.monitor_weight;
      case 'litter':
        return Icons.cleaning_services;
      case 'play':
        return Icons.sports_tennis;
      case 'groom':
        return Icons.content_cut;
      default:
        return Icons.note;
    }
  }

  /// 타임라인용 아이콘 (상세 타입 + 간단 타입 모두 지원)
  static IconData getIconForAnyType(String type) {
    switch (type.toLowerCase()) {
      case 'food_meal':
        return Icons.restaurant;
      case 'food_snack':
        return Icons.cookie;
      case 'food_water':
        return Icons.water_drop;
      case 'health_med':
      case 'food_med':
        return Icons.medical_services;
      case 'health_supplement':
      case 'food_supplement':
        return Icons.medication;
      case 'health_symptom':
        return Icons.medical_information;
      case 'activity_play':
        return Icons.sports_tennis;
      case 'activity_explore':
        return Icons.explore_outlined;
      case 'activity_outing':
        return Icons.directions_walk;
      case 'activity_walk':
        return Icons.directions_walk;
      case 'activity_rest':
        return Icons.hotel_outlined;
      case 'activity_other':
        return Icons.more_horiz;
      case 'poop_urine':
        return Icons.opacity;
      case 'poop_feces':
        return Icons.pets;
      case 'poop_other':
        return Icons.more_horiz;
      case 'grooming':
        return Icons.content_cut;
      case 'health':
        return Icons.favorite;
      default:
        return Icons.note;
    }
  }

  /// 레코드 타입의 번역된 라벨 반환
  static String getLabelForType(BuildContext context, String type) {
    final key = 'records.items.$type';
    final translated = tr(key, context: context);
    if (translated != key) {
      return translated;
    }
    final category = categoryForRecordType(type);
    final fallbackKey = 'records.type.${_translationCategoryKey(category)}';
    final fallback = tr(fallbackKey, context: context);
    return fallback != fallbackKey ? fallback : type;
  }

  /// 레코드 타입에서 카테고리 추출
  static String categoryForRecordType(String type) {
    switch (type.toLowerCase()) {
      case 'food_meal':
      case 'food_snack':
      case 'food_water':
      case 'food_med':
      case 'food_supplement':
        return 'food';
      case 'health_med':
      case 'health_supplement':
      case 'health_vaccine':
      case 'health_visit':
      case 'health_weight':
      case 'health_symptom':
        return 'health';
      case 'poop_feces':
      case 'poop_urine':
      case 'poop_other':
      case 'hygiene_brush':
        return 'poop';
      case 'activity_play':
      case 'activity_explore':
      case 'activity_outing':
      case 'activity_walk':
      case 'activity_rest':
      case 'activity_other':
      case 'grooming':
        return 'activity';
      default:
        return 'food';
    }
  }

  static String _translationCategoryKey(String category) {
    if (category == 'activity') {
      return 'play';
    }
    return category;
  }
}
