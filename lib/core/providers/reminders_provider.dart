import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/data/models/reminder.dart';
import 'package:petcare/data/repositories/reminders_repository.dart';

/// State class for reminders list
class RemindersState {
  const RemindersState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Reminder> reminders;
  final bool isLoading;
  final String? error;

  RemindersState copyWith({
    List<Reminder>? reminders,
    bool? isLoading,
    String? error,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Reminders provider notifier
class RemindersNotifier extends StateNotifier<RemindersState> {
  RemindersNotifier(this._repository) : super(const RemindersState());

  final RemindersRepository _repository;

  /// Load all reminders
  Future<void> loadReminders([String? petId]) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reminders = petId != null
          ? await _repository.getRemindersForPet(petId)
          : await _repository.getAllReminders();

      state = state.copyWith(
        reminders: reminders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new reminder
  Future<void> addReminder(Reminder reminder) async {
    final oldReminders = state.reminders;
    final updatedReminders = [reminder, ...oldReminders];
    state = state.copyWith(reminders: updatedReminders); // Optimistic update

    try {
      final savedReminder = await _repository.createReminder(reminder);
      final finalReminders = [savedReminder, ...oldReminders];
      state = state.copyWith(reminders: finalReminders);
    } catch (e) {
      state = state.copyWith(reminders: oldReminders, error: e.toString());
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder updatedReminder) async {
    final oldReminders = state.reminders;
    final updatedReminders = state.reminders.map((reminder) {
      return reminder.id == updatedReminder.id ? updatedReminder : reminder;
    }).toList();
    state = state.copyWith(reminders: updatedReminders); // Optimistic update

    try {
      final savedReminder = await _repository.updateReminder(updatedReminder);
      final finalReminders = state.reminders.map((reminder) {
        return reminder.id == savedReminder.id ? savedReminder : reminder;
      }).toList();
      state = state.copyWith(reminders: finalReminders);
    } catch (e) {
      state = state.copyWith(reminders: oldReminders, error: e.toString());
    }
  }

  /// Mark reminder as done
  Future<void> markReminderDone(String reminderId) async {
    final oldReminders = state.reminders;
    final updatedReminders = state.reminders.map((reminder) {
      if (reminder.id == reminderId) {
        return reminder.copyWith(done: true);
      }
      return reminder;
    }).toList();
    state = state.copyWith(reminders: updatedReminders); // Optimistic update

    try {
      final savedReminder = await _repository.markReminderDone(reminderId);
      final finalReminders = state.reminders.map((reminder) {
        return reminder.id == savedReminder.id ? savedReminder : reminder;
      }).toList();
      state = state.copyWith(reminders: finalReminders);
    } catch (e) {
      state = state.copyWith(reminders: oldReminders, error: e.toString());
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    final oldReminders = state.reminders;
    final updatedReminders = state.reminders.where((reminder) => reminder.id != reminderId).toList();
    state = state.copyWith(reminders: updatedReminders); // Optimistic update

    try {
      await _repository.deleteReminder(reminderId);
    } catch (e) {
      state = state.copyWith(reminders: oldReminders, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Reminders provider
final remindersProvider = StateNotifierProvider<RemindersNotifier, RemindersState>((ref) {
  return RemindersNotifier(ref.read(remindersRepositoryProvider));
});

/// Reminders for specific pet provider
final remindersForPetProvider = Provider.family<List<Reminder>, String>((ref, petId) {
  final remindersState = ref.watch(remindersProvider);
  return remindersState.reminders.where((reminder) => reminder.petId == petId).toList();
});

/// Upcoming reminders provider (next 7 days)
final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersState = ref.watch(remindersProvider);
  final now = DateTime.now();
  final sevenDaysFromNow = now.add(const Duration(days: 7));
  
  return remindersState.reminders.where((reminder) {
    return !reminder.done && 
           reminder.scheduledAt.isAfter(now) && 
           reminder.scheduledAt.isBefore(sevenDaysFromNow);
  }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

/// Overdue reminders provider
final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersState = ref.watch(remindersProvider);
  final now = DateTime.now();
  
  return remindersState.reminders.where((reminder) {
    return !reminder.done && reminder.scheduledAt.isBefore(now);
  }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

/// Today's reminders provider
final todaysRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersState = ref.watch(remindersProvider);
  final today = DateTime.now();
  
  return remindersState.reminders.where((reminder) {
    final reminderDate = reminder.scheduledAt;
    return reminderDate.year == today.year &&
           reminderDate.month == today.month &&
           reminderDate.day == today.day;
  }).toList();
});

/// Reminders count provider
final remindersCountProvider = Provider<int>((ref) {
  final remindersState = ref.watch(remindersProvider);
  return remindersState.reminders.length;
});
