import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/data/models/emergency_contact.dart';
import 'package:petcare/data/repositories/emergency_contact_repository.dart';

/// State class for emergency contacts list
class EmergencyContactState {
  const EmergencyContactState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<EmergencyContact> contacts;
  final bool isLoading;
  final String? error;

  EmergencyContactState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return EmergencyContactState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Emergency contact provider notifier
class EmergencyContactNotifier extends StateNotifier<EmergencyContactState> {
  EmergencyContactNotifier(this._repository)
      : super(const EmergencyContactState());

  final EmergencyContactRepository _repository;

  /// Load contacts for a specific pet
  Future<void> loadContacts(String petId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final contacts = await _repository.getContactsForPet(petId);
      state = state.copyWith(
        contacts: contacts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new contact
  Future<void> addContact(EmergencyContact contact) async {
    final oldContacts = state.contacts;
    final updatedContacts = [contact, ...oldContacts];
    state = state.copyWith(contacts: updatedContacts);

    try {
      final savedContact = await _repository.createContact(contact);
      final finalContacts = [savedContact, ...oldContacts];
      state = state.copyWith(contacts: finalContacts);
    } catch (e) {
      state = state.copyWith(contacts: oldContacts, error: e.toString());
    }
  }

  /// Update an existing contact
  Future<void> updateContact(EmergencyContact updatedContact) async {
    final oldContacts = state.contacts;
    final updatedContacts = state.contacts.map((contact) {
      return contact.id == updatedContact.id ? updatedContact : contact;
    }).toList();
    state = state.copyWith(contacts: updatedContacts);

    try {
      final savedContact = await _repository.updateContact(updatedContact);
      final finalContacts = state.contacts.map((contact) {
        return contact.id == savedContact.id ? savedContact : contact;
      }).toList();
      state = state.copyWith(contacts: finalContacts);
    } catch (e) {
      state = state.copyWith(contacts: oldContacts, error: e.toString());
    }
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId) async {
    final oldContacts = state.contacts;
    final updatedContacts =
        state.contacts.where((contact) => contact.id != contactId).toList();
    state = state.copyWith(contacts: updatedContacts);

    try {
      await _repository.deleteContact(contactId);
    } catch (e) {
      state = state.copyWith(contacts: oldContacts, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Emergency contact provider
final emergencyContactProvider =
    StateNotifierProvider<EmergencyContactNotifier, EmergencyContactState>(
        (ref) {
  return EmergencyContactNotifier(ref.read(emergencyContactRepositoryProvider));
});

/// Contacts for specific pet provider
final contactsForPetProvider =
    Provider.family<List<EmergencyContact>, String>((ref, petId) {
  final contactState = ref.watch(emergencyContactProvider);
  return contactState.contacts
      .where((contact) => contact.petId == petId)
      .toList();
});

/// Contacts grouped by type for a specific pet
final contactsByTypeProvider =
    Provider.family<Map<String, List<EmergencyContact>>, String>((ref, petId) {
  final contacts = ref.watch(contactsForPetProvider(petId));
  final grouped = <String, List<EmergencyContact>>{};
  for (final contact in contacts) {
    grouped.putIfAbsent(contact.contactType, () => []).add(contact);
  }
  return grouped;
});
