// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmergencyContactImpl _$$EmergencyContactImplFromJson(
  Map<String, dynamic> json,
) => _$EmergencyContactImpl(
  id: json['id'] as String,
  petId: json['petId'] as String,
  contactType: json['contactType'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  address: json['address'] as String?,
  operatingHours: json['operatingHours'] as String?,
  notes: json['notes'] as String?,
  isPrimary: json['isPrimary'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$EmergencyContactImplToJson(
  _$EmergencyContactImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'petId': instance.petId,
  'contactType': instance.contactType,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'operatingHours': instance.operatingHours,
  'notes': instance.notes,
  'isPrimary': instance.isPrimary,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
