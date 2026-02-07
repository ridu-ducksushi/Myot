import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/repositories/pets_repository.dart';
import 'package:petcare/utils/app_logger.dart';

/// State class for pets list
class PetsState {
  const PetsState({
    this.pets = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Pet> pets;
  final bool isLoading;
  final String? error;

  PetsState copyWith({
    List<Pet>? pets,
    bool? isLoading,
    String? error,
  }) {
    return PetsState(
      pets: pets ?? this.pets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Pets provider notifier
class PetsNotifier extends StateNotifier<PetsState> {
  PetsNotifier(this._petsRepository) : super(const PetsState());
  
  final PetsRepository _petsRepository;

  /// Load all pets
  Future<void> loadPets() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.d('PetsProvider', '펫 데이터 로드 시작...');
      final pets = await _petsRepository.getAllPets();
      AppLogger.d('PetsProvider', '${pets.length}개 펫 로드 완료');
      
      state = state.copyWith(
        pets: pets,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.e('PetsProvider', '펫 로드 실패', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new pet
  Future<void> addPet(Pet pet) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.d('PetsProvider', '새 펫 추가 시작: ${pet.name}');
      final savedPet = await _petsRepository.createPet(pet);
      
      final updatedPets = [...state.pets, savedPet];
      state = state.copyWith(
        pets: updatedPets,
        isLoading: false,
      );
      AppLogger.d('PetsProvider', '펫 추가 완료: ${savedPet.name}');
    } catch (e) {
      AppLogger.e('PetsProvider', '펫 추가 실패', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update an existing pet
  Future<void> updatePet(Pet updatedPet) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.d('PetsProvider', '펫 업데이트 시작: ${updatedPet.name}');
      final savedPet = await _petsRepository.updatePet(updatedPet);
      
      final updatedPets = state.pets.map((pet) {
        return pet.id == savedPet.id ? savedPet : pet;
      }).toList();
      
      state = state.copyWith(
        pets: updatedPets,
        isLoading: false,
      );
      AppLogger.d('PetsProvider', '펫 업데이트 완료: ${savedPet.name}');
    } catch (e) {
      AppLogger.e('PetsProvider', '펫 업데이트 실패', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a pet
  Future<void> deletePet(String petId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      AppLogger.d('PetsProvider', '펫 삭제 시작: $petId');
      await _petsRepository.deletePet(petId);
      
      final updatedPets = state.pets.where((pet) => pet.id != petId).toList();
      state = state.copyWith(
        pets: updatedPets,
        isLoading: false,
      );
      AppLogger.d('PetsProvider', '펫 삭제 완료: $petId');
    } catch (e) {
      AppLogger.e('PetsProvider', '펫 삭제 실패', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get pet by ID
  Pet? getPetById(String petId) {
    try {
      return state.pets.firstWhere((pet) => pet.id == petId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Pets provider
final petsProvider = StateNotifierProvider<PetsNotifier, PetsState>((ref) {
  final petsRepository = ref.watch(petsRepositoryProvider);
  return PetsNotifier(petsRepository);
});

/// Selected pet provider
final selectedPetProvider = StateProvider<Pet?>((ref) => null);

/// Pet by ID provider
final petByIdProvider = Provider.family<Pet?, String>((ref, petId) {
  final petsState = ref.watch(petsProvider);
  try {
    return petsState.pets.firstWhere((pet) => pet.id == petId);
  } catch (e) {
    return null;
  }
});

/// Pets count provider
final petsCountProvider = Provider<int>((ref) {
  final petsState = ref.watch(petsProvider);
  return petsState.pets.length;
});

final lastUserIdProvider = StateProvider<String?>((ref) => null);
