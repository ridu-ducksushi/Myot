import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/models/pet_allergy.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/base_repository.dart';
import 'package:petcare/utils/app_logger.dart';

/// Repository for pet allergy data management
class PetAllergyRepository extends BaseRepository {
  PetAllergyRepository({
    required super.supabase,
    required super.localDb,
  });

  @override
  String get tag => 'PetAllergyRepo';

  Map<String, dynamic> _toSupabaseRow(PetAllergy allergy) {
    return {
      'pet_id': allergy.petId,
      'allergen': allergy.allergen,
      'reaction': allergy.reaction,
      'severity': allergy.severity,
      'notes': allergy.notes,
      'diagnosed_at': allergy.diagnosedAt?.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }

  PetAllergy _fromSupabaseRow(Map<String, dynamic> row) {
    return PetAllergy(
      id: row['id'] as String,
      petId: row['pet_id'] as String,
      allergen: row['allergen'] as String,
      reaction: row['reaction'] as String?,
      severity: row['severity'] as String? ?? 'moderate',
      notes: row['notes'] as String?,
      diagnosedAt: row['diagnosed_at'] != null
          ? DateTime.tryParse(row['diagnosed_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Get all allergies for a pet
  Future<List<PetAllergy>> getAllergiesForPet(String petId) async {
    try {
      final response = await supabase
          .from('pet_allergies')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      final allergies = (response as List)
          .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
          .toList();

      return allergies;
    } catch (e) {
      AppLogger.e(tag, 'Failed to fetch allergies from Supabase', e);
      return [];
    }
  }

  /// Create a new allergy record
  Future<PetAllergy> createAllergy(PetAllergy allergy) async {
    try {
      final insertRow = _toSupabaseRow(allergy);
      final response = await supabase
          .from('pet_allergies')
          .insert(insertRow)
          .select()
          .single();

      return _fromSupabaseRow(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(tag, 'createAllergy failed', e);
      return allergy;
    }
  }

  /// Update an existing allergy record
  Future<PetAllergy> updateAllergy(PetAllergy allergy) async {
    try {
      final updateRow = _toSupabaseRow(allergy);
      final response = await supabase
          .from('pet_allergies')
          .update(updateRow)
          .eq('id', allergy.id)
          .select()
          .single();

      return _fromSupabaseRow(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(tag, 'updateAllergy failed', e);
      return allergy;
    }
  }

  /// Delete an allergy record
  Future<void> deleteAllergy(String id) async {
    try {
      await supabase.from('pet_allergies').delete().eq('id', id);
    } catch (e) {
      AppLogger.e(tag, 'deleteAllergy failed', e);
    }
  }
}

/// Provider for pet allergy repository
final petAllergyRepositoryProvider = Provider<PetAllergyRepository>((ref) {
  return PetAllergyRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});
