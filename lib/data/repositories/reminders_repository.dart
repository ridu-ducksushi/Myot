import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/models/reminder.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/base_repository.dart';
import 'package:petcare/utils/app_logger.dart';

/// Repository for reminder data management
class RemindersRepository extends BaseRepository {
  RemindersRepository({
    required super.supabase,
    required super.localDb,
  });

  @override
  String get tag => 'RemindersRepo';

  /// Get all reminders for a pet
  Future<List<Reminder>> getRemindersForPet(String petId) async {
    try {
      // Try to fetch from Supabase first
      final response = await supabase
          .from('reminders')
          .select()
          .eq('pet_id', petId)
          .order('scheduled_at', ascending: true);

      final reminders = (response as List)
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache locally
      for (final reminder in reminders) {
        await localDb.saveReminder(reminder);
      }

      return reminders;
    } catch (e) {
      AppLogger.e('RemindersRepo', 'Failed to fetch reminders from Supabase', e);
      // Fallback to local database
      return await localDb.getRemindersForPet(petId);
    }
  }

  /// Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    try {
      // Try to fetch from Supabase first
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Get reminders for user's pets
        final response = await supabase
            .from('reminders')
            .select('''
              *,
              pets!inner(owner_id)
            ''')
            .eq('pets.owner_id', user.id)
            .order('scheduled_at', ascending: true);

        final reminders = (response as List)
            .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache locally
        for (final reminder in reminders) {
          await localDb.saveReminder(reminder);
        }

        return reminders;
      }
    } catch (e) {
      AppLogger.e('RemindersRepo', 'Failed to fetch reminders from Supabase', e);
    }

    // Fallback to local database
    return await localDb.getAllReminders();
  }

  /// Get upcoming reminders (next 7 days)
  Future<List<Reminder>> getUpcomingReminders() async {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('reminders')
            .select('''
              *,
              pets!inner(owner_id)
            ''')
            .eq('pets.owner_id', user.id)
            .eq('done', false)
            .gte('scheduled_at', now.toIso8601String())
            .lte('scheduled_at', sevenDaysFromNow.toIso8601String())
            .order('scheduled_at', ascending: true);

        return (response as List)
            .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('RemindersRepo', 'Failed to fetch upcoming reminders from Supabase', e);
    }

    // Fallback to filtering local reminders
    final allReminders = await localDb.getAllReminders();
    return allReminders.where((reminder) {
      return !reminder.done && 
             reminder.scheduledAt.isAfter(now) && 
             reminder.scheduledAt.isBefore(sevenDaysFromNow);
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get overdue reminders
  Future<List<Reminder>> getOverdueReminders() async {
    final now = DateTime.now();

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('reminders')
            .select('''
              *,
              pets!inner(owner_id)
            ''')
            .eq('pets.owner_id', user.id)
            .eq('done', false)
            .lt('scheduled_at', now.toIso8601String())
            .order('scheduled_at', ascending: true);

        return (response as List)
            .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('RemindersRepo', 'Failed to fetch overdue reminders from Supabase', e);
    }

    // Fallback to filtering local reminders
    final allReminders = await localDb.getAllReminders();
    return allReminders.where((reminder) {
      return !reminder.done && reminder.scheduledAt.isBefore(now);
    }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Create a new reminder
  Future<Reminder> createReminder(Reminder reminder) async {
    return saveWithCloudFallback<Reminder>(
      operationName: 'createReminder',
      cloudAction: () async {
        final response = await supabase
            .from('reminders')
            .insert(reminder.toJson())
            .select()
            .single();

        final savedReminder = Reminder.fromJson(response as Map<String, dynamic>);
        await localDb.saveReminder(savedReminder);
        return savedReminder;
      },
      localSave: () => localDb.saveReminder(reminder),
      fallbackValue: reminder,
    );
  }

  /// Update an existing reminder
  Future<Reminder> updateReminder(Reminder reminder) async {
    return saveWithCloudFallback<Reminder>(
      operationName: 'updateReminder',
      cloudAction: () async {
        final response = await supabase
            .from('reminders')
            .update(reminder.toJson())
            .eq('id', reminder.id)
            .select()
            .single();

        final updatedReminder = Reminder.fromJson(response as Map<String, dynamic>);
        await localDb.saveReminder(updatedReminder);
        return updatedReminder;
      },
      localSave: () => localDb.saveReminder(reminder),
      fallbackValue: reminder,
    );
  }

  /// Mark reminder as done
  Future<Reminder> markReminderDone(String id) async {
    return withCloudFallback<Reminder>(
      operationName: 'markReminderDone',
      cloudAction: () async {
        final response = await supabase
            .from('reminders')
            .update({'done': true})
            .eq('id', id)
            .select()
            .single();

        final updatedReminder = Reminder.fromJson(response as Map<String, dynamic>);
        await localDb.saveReminder(updatedReminder);
        return updatedReminder;
      },
      localFallback: () async {
        final currentReminder = await localDb.getAllReminders();
        final reminder = currentReminder.firstWhere((r) => r.id == id);
        final updatedReminder = reminder.copyWith(done: true);
        await localDb.saveReminder(updatedReminder);
        return updatedReminder;
      },
    );
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    return deleteWithCloudFallback(
      operationName: 'deleteReminder',
      cloudAction: () => supabase.from('reminders').delete().eq('id', id),
      localDelete: () => localDb.deleteReminder(id),
    );
  }

  /// Sync local changes to Supabase
  Future<void> syncToCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // TODO: Implement conflict resolution and sync logic
      AppLogger.d('RemindersRepo', 'Syncing reminders to cloud...');
    } catch (e) {
      AppLogger.e('RemindersRepo', 'Failed to sync reminders to cloud', e);
    }
  }
}

/// Provider for reminders repository
final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});
