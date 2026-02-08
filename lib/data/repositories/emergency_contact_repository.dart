import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/models/emergency_contact.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/base_repository.dart';
import 'package:petcare/utils/app_logger.dart';

/// Repository for emergency contact data management
class EmergencyContactRepository extends BaseRepository {
  EmergencyContactRepository({
    required super.supabase,
    required super.localDb,
  });

  @override
  String get tag => 'EmergencyContactRepo';

  Map<String, dynamic> _toSupabaseRow(EmergencyContact contact) {
    return {
      'pet_id': contact.petId,
      'contact_type': contact.contactType,
      'name': contact.name,
      'phone': contact.phone,
      'address': contact.address,
      'operating_hours': contact.operatingHours,
      'notes': contact.notes,
      'is_primary': contact.isPrimary,
    }..removeWhere((k, v) => v == null);
  }

  EmergencyContact _fromSupabaseRow(Map<String, dynamic> row) {
    return EmergencyContact(
      id: row['id'] as String,
      petId: row['pet_id'] as String,
      contactType: row['contact_type'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      address: row['address'] as String?,
      operatingHours: row['operating_hours'] as String?,
      notes: row['notes'] as String?,
      isPrimary: row['is_primary'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Get all emergency contacts for a pet
  Future<List<EmergencyContact>> getContactsForPet(String petId) async {
    try {
      final response = await supabase
          .from('emergency_contacts')
          .select()
          .eq('pet_id', petId)
          .order('is_primary', ascending: false)
          .order('contact_type', ascending: true);

      final contacts = (response as List)
          .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
          .toList();

      return contacts;
    } catch (e) {
      AppLogger.e(tag, 'Failed to fetch emergency contacts', e);
      return [];
    }
  }

  /// Create a new emergency contact
  Future<EmergencyContact> createContact(EmergencyContact contact) async {
    try {
      final insertRow = _toSupabaseRow(contact);
      final response = await supabase
          .from('emergency_contacts')
          .insert(insertRow)
          .select()
          .single();

      return _fromSupabaseRow(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(tag, 'createContact failed', e);
      return contact;
    }
  }

  /// Update an existing emergency contact
  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    try {
      final updateRow = _toSupabaseRow(contact);
      final response = await supabase
          .from('emergency_contacts')
          .update(updateRow)
          .eq('id', contact.id)
          .select()
          .single();

      return _fromSupabaseRow(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(tag, 'updateContact failed', e);
      return contact;
    }
  }

  /// Delete an emergency contact
  Future<void> deleteContact(String id) async {
    try {
      await supabase.from('emergency_contacts').delete().eq('id', id);
    } catch (e) {
      AppLogger.e(tag, 'deleteContact failed', e);
    }
  }
}

/// Provider for emergency contact repository
final emergencyContactRepositoryProvider =
    Provider<EmergencyContactRepository>((ref) {
  return EmergencyContactRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});
