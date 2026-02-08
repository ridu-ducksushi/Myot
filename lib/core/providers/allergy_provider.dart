import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/data/models/pet_allergy.dart';
import 'package:petcare/data/repositories/pet_allergy_repository.dart';

/// State class for allergies list
class AllergyState {
  const AllergyState({
    this.allergies = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PetAllergy> allergies;
  final bool isLoading;
  final String? error;

  AllergyState copyWith({
    List<PetAllergy>? allergies,
    bool? isLoading,
    String? error,
  }) {
    return AllergyState(
      allergies: allergies ?? this.allergies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Allergy provider notifier
class AllergyNotifier extends StateNotifier<AllergyState> {
  AllergyNotifier(this._repository) : super(const AllergyState());

  final PetAllergyRepository _repository;

  /// Load allergies for a specific pet
  Future<void> loadAllergies(String petId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allergies = await _repository.getAllergiesForPet(petId);
      state = state.copyWith(
        allergies: allergies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new allergy
  Future<void> addAllergy(PetAllergy allergy) async {
    final oldAllergies = state.allergies;
    final updatedAllergies = [allergy, ...oldAllergies];
    state = state.copyWith(allergies: updatedAllergies);

    try {
      final savedAllergy = await _repository.createAllergy(allergy);
      final finalAllergies = [savedAllergy, ...oldAllergies];
      state = state.copyWith(allergies: finalAllergies);
    } catch (e) {
      state = state.copyWith(allergies: oldAllergies, error: e.toString());
    }
  }

  /// Update an existing allergy
  Future<void> updateAllergy(PetAllergy updatedAllergy) async {
    final oldAllergies = state.allergies;
    final updatedAllergies = state.allergies.map((allergy) {
      return allergy.id == updatedAllergy.id ? updatedAllergy : allergy;
    }).toList();
    state = state.copyWith(allergies: updatedAllergies);

    try {
      final savedAllergy = await _repository.updateAllergy(updatedAllergy);
      final finalAllergies = state.allergies.map((allergy) {
        return allergy.id == savedAllergy.id ? savedAllergy : allergy;
      }).toList();
      state = state.copyWith(allergies: finalAllergies);
    } catch (e) {
      state = state.copyWith(allergies: oldAllergies, error: e.toString());
    }
  }

  /// Delete an allergy
  Future<void> deleteAllergy(String allergyId) async {
    final oldAllergies = state.allergies;
    final updatedAllergies =
        state.allergies.where((allergy) => allergy.id != allergyId).toList();
    state = state.copyWith(allergies: updatedAllergies);

    try {
      await _repository.deleteAllergy(allergyId);
    } catch (e) {
      state = state.copyWith(allergies: oldAllergies, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Allergy provider
final allergyProvider =
    StateNotifierProvider<AllergyNotifier, AllergyState>((ref) {
  return AllergyNotifier(ref.read(petAllergyRepositoryProvider));
});

/// Allergies for specific pet provider
final allergiesForPetProvider =
    Provider.family<List<PetAllergy>, String>((ref, petId) {
  final allergyState = ref.watch(allergyProvider);
  return allergyState.allergies
      .where((allergy) => allergy.petId == petId)
      .toList();
});
