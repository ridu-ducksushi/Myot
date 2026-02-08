// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_allergy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PetAllergy _$PetAllergyFromJson(Map<String, dynamic> json) {
  return _PetAllergy.fromJson(json);
}

/// @nodoc
mixin _$PetAllergy {
  String get id => throw _privateConstructorUsedError;
  String get petId => throw _privateConstructorUsedError;
  String get allergen => throw _privateConstructorUsedError;
  String? get reaction => throw _privateConstructorUsedError;
  String get severity =>
      throw _privateConstructorUsedError; // mild|moderate|severe
  String? get notes => throw _privateConstructorUsedError;
  DateTime? get diagnosedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PetAllergy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PetAllergy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PetAllergyCopyWith<PetAllergy> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PetAllergyCopyWith<$Res> {
  factory $PetAllergyCopyWith(
    PetAllergy value,
    $Res Function(PetAllergy) then,
  ) = _$PetAllergyCopyWithImpl<$Res, PetAllergy>;
  @useResult
  $Res call({
    String id,
    String petId,
    String allergen,
    String? reaction,
    String severity,
    String? notes,
    DateTime? diagnosedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$PetAllergyCopyWithImpl<$Res, $Val extends PetAllergy>
    implements $PetAllergyCopyWith<$Res> {
  _$PetAllergyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PetAllergy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? allergen = null,
    Object? reaction = freezed,
    Object? severity = null,
    Object? notes = freezed,
    Object? diagnosedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            petId: null == petId
                ? _value.petId
                : petId // ignore: cast_nullable_to_non_nullable
                      as String,
            allergen: null == allergen
                ? _value.allergen
                : allergen // ignore: cast_nullable_to_non_nullable
                      as String,
            reaction: freezed == reaction
                ? _value.reaction
                : reaction // ignore: cast_nullable_to_non_nullable
                      as String?,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            diagnosedAt: freezed == diagnosedAt
                ? _value.diagnosedAt
                : diagnosedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PetAllergyImplCopyWith<$Res>
    implements $PetAllergyCopyWith<$Res> {
  factory _$$PetAllergyImplCopyWith(
    _$PetAllergyImpl value,
    $Res Function(_$PetAllergyImpl) then,
  ) = __$$PetAllergyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String petId,
    String allergen,
    String? reaction,
    String severity,
    String? notes,
    DateTime? diagnosedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$PetAllergyImplCopyWithImpl<$Res>
    extends _$PetAllergyCopyWithImpl<$Res, _$PetAllergyImpl>
    implements _$$PetAllergyImplCopyWith<$Res> {
  __$$PetAllergyImplCopyWithImpl(
    _$PetAllergyImpl _value,
    $Res Function(_$PetAllergyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PetAllergy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? petId = null,
    Object? allergen = null,
    Object? reaction = freezed,
    Object? severity = null,
    Object? notes = freezed,
    Object? diagnosedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PetAllergyImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        petId: null == petId
            ? _value.petId
            : petId // ignore: cast_nullable_to_non_nullable
                  as String,
        allergen: null == allergen
            ? _value.allergen
            : allergen // ignore: cast_nullable_to_non_nullable
                  as String,
        reaction: freezed == reaction
            ? _value.reaction
            : reaction // ignore: cast_nullable_to_non_nullable
                  as String?,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        diagnosedAt: freezed == diagnosedAt
            ? _value.diagnosedAt
            : diagnosedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PetAllergyImpl implements _PetAllergy {
  const _$PetAllergyImpl({
    required this.id,
    required this.petId,
    required this.allergen,
    this.reaction,
    this.severity = 'moderate',
    this.notes,
    this.diagnosedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$PetAllergyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PetAllergyImplFromJson(json);

  @override
  final String id;
  @override
  final String petId;
  @override
  final String allergen;
  @override
  final String? reaction;
  @override
  @JsonKey()
  final String severity;
  // mild|moderate|severe
  @override
  final String? notes;
  @override
  final DateTime? diagnosedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PetAllergy(id: $id, petId: $petId, allergen: $allergen, reaction: $reaction, severity: $severity, notes: $notes, diagnosedAt: $diagnosedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PetAllergyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.petId, petId) || other.petId == petId) &&
            (identical(other.allergen, allergen) ||
                other.allergen == allergen) &&
            (identical(other.reaction, reaction) ||
                other.reaction == reaction) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.diagnosedAt, diagnosedAt) ||
                other.diagnosedAt == diagnosedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    petId,
    allergen,
    reaction,
    severity,
    notes,
    diagnosedAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PetAllergy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PetAllergyImplCopyWith<_$PetAllergyImpl> get copyWith =>
      __$$PetAllergyImplCopyWithImpl<_$PetAllergyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PetAllergyImplToJson(this);
  }
}

abstract class _PetAllergy implements PetAllergy {
  const factory _PetAllergy({
    required final String id,
    required final String petId,
    required final String allergen,
    final String? reaction,
    final String severity,
    final String? notes,
    final DateTime? diagnosedAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PetAllergyImpl;

  factory _PetAllergy.fromJson(Map<String, dynamic> json) =
      _$PetAllergyImpl.fromJson;

  @override
  String get id;
  @override
  String get petId;
  @override
  String get allergen;
  @override
  String? get reaction;
  @override
  String get severity; // mild|moderate|severe
  @override
  String? get notes;
  @override
  DateTime? get diagnosedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of PetAllergy
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PetAllergyImplCopyWith<_$PetAllergyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
