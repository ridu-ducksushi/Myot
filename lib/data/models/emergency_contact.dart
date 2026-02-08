import 'package:freezed_annotation/freezed_annotation.dart';

part 'emergency_contact.freezed.dart';
part 'emergency_contact.g.dart';

@freezed
class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String id,
    required String petId,
    required String contactType, // vet_clinic|emergency_hospital|pet_sitter|other
    required String name,
    required String phone,
    String? address,
    String? operatingHours,
    String? notes,
    @Default(false) bool isPrimary,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}
