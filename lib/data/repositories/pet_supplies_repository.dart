import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/data/models/pet_supplies.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class PetSuppliesRepository extends BaseRepository {
  PetSuppliesRepository({
    required super.supabase,
    required super.localDb,
  });

  @override
  String get tag => 'SuppliesRepo';

  bool _isEmptySuppliesRow(Map<String, dynamic> row) {
    bool isEmpty(dynamic v) => v == null || (v is String && v.trim().isEmpty);
    return isEmpty(row['dry_food']) &&
        isEmpty(row['wet_food']) &&
        isEmpty(row['supplement']) &&
        isEmpty(row['snack']) &&
        isEmpty(row['litter']);
  }

  // 특정 날짜의 물품 기록 조회
  Future<PetSupplies?> getSuppliesByDate(String petId, DateTime date) async {
    return withCloudFallback<PetSupplies?>(
      operationName: 'getSuppliesByDate',
      cloudAction: () async {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final response = await supabase
            .from('pet_supplies')
            .select()
            .eq('pet_id', petId)
            .gte('recorded_at', startOfDay.toIso8601String())
            .lt('recorded_at', endOfDay.toIso8601String())
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) return null;
        if (_isEmptySuppliesRow(response)) return null;

        final supplies = PetSupplies.fromJson(_fromSupabaseRow(response));
        await localDb.saveSupplies(supplies);
        return supplies;
      },
      localFallback: () => localDb.getSuppliesByDate(petId, date),
    );
  }

  // 특정 펫의 모든 물품 기록 날짜 조회
  Future<List<DateTime>> getSuppliesRecordDates(String petId) async {
    return withCloudFallback<List<DateTime>>(
      operationName: 'getSuppliesRecordDates',
      cloudAction: () async {
        final response = await supabase
            .from('pet_supplies')
            .select('recorded_at,dry_food,wet_food,supplement,snack,litter')
            .eq('pet_id', petId)
            .order('recorded_at', ascending: false);

        final filtered = (response as List)
            .where((row) => !_isEmptySuppliesRow(row as Map<String, dynamic>))
            .map((row) => DateTime.parse(row['recorded_at'] as String))
            .map((dt) => DateTime(dt.year, dt.month, dt.day))
            .toSet()
            .toList();

        return filtered;
      },
      localFallback: () async {
        final supplies = await localDb.getSuppliesForPet(petId);
        return supplies
            .map((s) => DateTime(s.recordedAt.year, s.recordedAt.month, s.recordedAt.day))
            .toSet()
            .toList();
      },
    );
  }

  // 물품 기록 저장/업데이트
  Future<PetSupplies> saveSupplies(PetSupplies supplies) async {
    return saveWithCloudFallback<PetSupplies>(
      operationName: 'saveSupplies',
      cloudAction: () async {
        final data = _toSupabaseRow(supplies);

        // 같은 날짜의 기록이 있는지 확인
        final startOfDay = DateTime(supplies.recordedAt.year, supplies.recordedAt.month, supplies.recordedAt.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final existingResponse = await supabase
            .from('pet_supplies')
            .select()
            .eq('pet_id', supplies.petId)
            .gte('recorded_at', startOfDay.toIso8601String())
            .lt('recorded_at', endOfDay.toIso8601String())
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final existing = existingResponse != null && !_isEmptySuppliesRow(existingResponse)
            ? PetSupplies.fromJson(_fromSupabaseRow(existingResponse))
            : null;

        bool isAllEmpty = [
          supplies.dryFood,
          supplies.wetFood,
          supplies.supplement,
          supplies.snack,
          supplies.litter,
        ].every((v) => v == null || v.trim().isEmpty);

        if (existing != null) {
          if (isAllEmpty) {
            await supabase.from('pet_supplies').delete().eq('id', existing.id);
            await localDb.deleteSupplies(existing.id);
            return supplies;
          }
          final response = await supabase
              .from('pet_supplies')
              .update(data)
              .eq('id', existing.id)
              .select()
              .single();

          final saved = PetSupplies.fromJson(_fromSupabaseRow(response));
          await localDb.saveSupplies(saved);
          return saved;
        } else {
          if (isAllEmpty) {
            return supplies;
          }
          final response = await supabase
              .from('pet_supplies')
              .insert(data)
              .select()
              .single();

          final saved = PetSupplies.fromJson(_fromSupabaseRow(response));
          await localDb.saveSupplies(saved);
          return saved;
        }
      },
      localSave: () => localDb.saveSupplies(supplies),
      fallbackValue: supplies,
    );
  }

  // 물품 기록 삭제
  Future<void> deleteSupplies(String id) async {
    return deleteWithCloudFallback(
      operationName: 'deleteSupplies',
      cloudAction: () => supabase.from('pet_supplies').delete().eq('id', id),
      localDelete: () => localDb.deleteSupplies(id),
    );
  }

  // Supabase snake_case → Flutter camelCase 변환
  Map<String, dynamic> _fromSupabaseRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'petId': row['pet_id'],
      'dryFood': row['dry_food'],
      'wetFood': row['wet_food'],
      'supplement': row['supplement'],
      'snack': row['snack'],
      'litter': row['litter'],
      'recordedAt': row['recorded_at'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  // Flutter camelCase → Supabase snake_case 변환
  Map<String, dynamic> _toSupabaseRow(PetSupplies supplies) {
    return {
      'id': supplies.id,
      'pet_id': supplies.petId,
      'dry_food': supplies.dryFood,
      'wet_food': supplies.wetFood,
      'supplement': supplies.supplement,
      'snack': supplies.snack,
      'litter': supplies.litter,
      'recorded_at': supplies.recordedAt.toIso8601String(),
      'created_at': supplies.createdAt.toIso8601String(),
      'updated_at': supplies.updatedAt.toIso8601String(),
    };
  }
}

/// Provider for pet supplies repository
final petSuppliesRepositoryProvider = Provider<PetSuppliesRepository>((ref) {
  return PetSuppliesRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});
