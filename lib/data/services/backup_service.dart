import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/data/models/reminder.dart';
import 'package:petcare/utils/app_logger.dart';

/// Result of a backup import operation
class BackupImportResult {
  final int petsImported;
  final int recordsImported;
  final int remindersImported;
  final int petsSkipped;
  final int recordsSkipped;
  final int remindersSkipped;

  const BackupImportResult({
    this.petsImported = 0,
    this.recordsImported = 0,
    this.remindersImported = 0,
    this.petsSkipped = 0,
    this.recordsSkipped = 0,
    this.remindersSkipped = 0,
  });

  int get totalImported => petsImported + recordsImported + remindersImported;
  int get totalSkipped => petsSkipped + recordsSkipped + remindersSkipped;
}

/// Service for backup and restore operations
class BackupService {
  static const String _backupVersion = '1.0';
  static const String _tag = 'BackupService';

  /// Export all user data to JSON string
  static Future<String> exportToJson() async {
    final localDb = LocalDatabase.instance;

    final pets = await localDb.getAllPets();
    final records = await localDb.getAllRecords();
    final reminders = await localDb.getAllReminders();

    AppLogger.d(_tag, 'Exporting: ${pets.length} pets, ${records.length} records, ${reminders.length} reminders');

    final backup = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.2+14',
      'data': {
        'pets': pets.map((p) => p.toJson()).toList(),
        'records': records.map((r) => r.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Import data from JSON string
  static Future<BackupImportResult> importFromJson(String jsonString) async {
    final localDb = LocalDatabase.instance;

    final Map<String, dynamic> backup = json.decode(jsonString) as Map<String, dynamic>;

    // Validate backup format
    if (!backup.containsKey('version') || !backup.containsKey('data')) {
      throw const FormatException('Invalid backup file format');
    }

    final data = backup['data'] as Map<String, dynamic>;

    // Get existing data for conflict detection
    final existingPets = await localDb.getAllPets();
    final existingRecords = await localDb.getAllRecords();
    final existingReminders = await localDb.getAllReminders();

    final existingPetIds = existingPets.map((p) => p.id).toSet();
    final existingRecordIds = existingRecords.map((r) => r.id).toSet();
    final existingReminderIds = existingReminders.map((r) => r.id).toSet();

    // Update ownerId to current user if logged in
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    int petsImported = 0;
    int petsSkipped = 0;
    int recordsImported = 0;
    int recordsSkipped = 0;
    int remindersImported = 0;
    int remindersSkipped = 0;

    // Import pets
    final petsList = data['pets'] as List<dynamic>? ?? [];
    for (final petJson in petsList) {
      try {
        var pet = Pet.fromJson(petJson as Map<String, dynamic>);
        if (currentUserId != null) {
          pet = pet.copyWith(ownerId: currentUserId);
        }

        if (existingPetIds.contains(pet.id)) {
          // Skip existing - don't overwrite
          petsSkipped++;
          continue;
        }

        await localDb.savePet(pet);
        petsImported++;
      } catch (e) {
        AppLogger.e(_tag, 'Failed to import pet', e);
        petsSkipped++;
      }
    }

    // Import records
    final recordsList = data['records'] as List<dynamic>? ?? [];
    for (final recordJson in recordsList) {
      try {
        final record = Record.fromJson(recordJson as Map<String, dynamic>);

        if (existingRecordIds.contains(record.id)) {
          recordsSkipped++;
          continue;
        }

        await localDb.saveRecord(record);
        recordsImported++;
      } catch (e) {
        AppLogger.e(_tag, 'Failed to import record', e);
        recordsSkipped++;
      }
    }

    // Import reminders
    final remindersList = data['reminders'] as List<dynamic>? ?? [];
    for (final reminderJson in remindersList) {
      try {
        final reminder = Reminder.fromJson(reminderJson as Map<String, dynamic>);

        if (existingReminderIds.contains(reminder.id)) {
          remindersSkipped++;
          continue;
        }

        await localDb.saveReminder(reminder);
        remindersImported++;
      } catch (e) {
        AppLogger.e(_tag, 'Failed to import reminder', e);
        remindersSkipped++;
      }
    }

    AppLogger.d(_tag, 'Import complete: $petsImported pets, $recordsImported records, $remindersImported reminders imported');

    return BackupImportResult(
      petsImported: petsImported,
      recordsImported: recordsImported,
      remindersImported: remindersImported,
      petsSkipped: petsSkipped,
      recordsSkipped: recordsSkipped,
      remindersSkipped: remindersSkipped,
    );
  }

  /// Save backup to a file and return the File
  static Future<File> saveToFile() async {
    final jsonData = await exportToJson();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${directory.path}/myot_backup_$timestamp.json');
    await file.writeAsString(jsonData);
    AppLogger.d(_tag, 'Backup saved to: ${file.path}');
    return file;
  }

  /// Share backup file using system share sheet
  static Future<void> shareBackup() async {
    final file = await saveToFile();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Myot Backup',
      ),
    );
  }

  /// Read backup from a file path and import
  static Future<BackupImportResult> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('Backup file not found');
    }

    final jsonString = await file.readAsString();
    return importFromJson(jsonString);
  }
}
