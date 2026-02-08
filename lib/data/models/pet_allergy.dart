import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_allergy.freezed.dart';
part 'pet_allergy.g.dart';

@freezed
class PetAllergy with _$PetAllergy {
  const factory PetAllergy({
    required String id,
    required String petId,
    required String allergen,
    String? reaction,
    @Default('moderate') String severity, // mild|moderate|severe
    String? notes,
    DateTime? diagnosedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PetAllergy;

  factory PetAllergy.fromJson(Map<String, dynamic> json) =>
      _$PetAllergyFromJson(json);
}
