// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_allergy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PetAllergyImpl _$$PetAllergyImplFromJson(Map<String, dynamic> json) =>
    _$PetAllergyImpl(
      id: json['id'] as String,
      petId: json['petId'] as String,
      allergen: json['allergen'] as String,
      reaction: json['reaction'] as String?,
      severity: json['severity'] as String? ?? 'moderate',
      notes: json['notes'] as String?,
      diagnosedAt: json['diagnosedAt'] == null
          ? null
          : DateTime.parse(json['diagnosedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PetAllergyImplToJson(_$PetAllergyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'petId': instance.petId,
      'allergen': instance.allergen,
      'reaction': instance.reaction,
      'severity': instance.severity,
      'notes': instance.notes,
      'diagnosedAt': instance.diagnosedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
