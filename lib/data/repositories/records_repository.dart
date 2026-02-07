import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/data/repositories/base_repository.dart';
import 'package:petcare/utils/app_logger.dart';

/// Repository for record data management
class RecordsRepository extends BaseRepository {
  RecordsRepository({
    required super.supabase,
    required super.localDb,
  });

  @override
  String get tag => 'RecordsRepo';

  Map<String, dynamic> _toSupabaseRow(Record record) {
    return {
      // Do NOT send id; let Supabase generate
      'pet_id': record.petId,
      'type': record.type,
      'title': record.title,
      'content': record.content,
      'value': record.value,
      'at': record.at.toIso8601String(),
      'files': record.files,
    }..removeWhere((k, v) => v == null);
  }

  bool _isValidUUID(String str) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(str);
  }

  Record _fromSupabaseRow(Map<String, dynamic> row) {
    return Record(
      id: row['id'] as String,
      petId: (row['pet_id'] as String),
      type: row['type'] as String,
      title: row['title'] as String? ?? '',
      content: row['content'] as String?,
      value: row['value'] as Map<String, dynamic>?,
      at: DateTime.tryParse(row['at'] as String? ?? '') ?? DateTime.now(),
      files: (row['files'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Get all records for a pet
  Future<List<Record>> getRecordsForPet(String petId) async {
    try {
      // Try to fetch from Supabase first
      final user = supabase.auth.currentUser;
      final response = await supabase
          .from('records')
          .select()
          .eq('pet_id', petId)
          .order('at', ascending: false);

      final records = (response as List)
          .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
          .toList();

      // Cache locally
      for (final record in records) {
        await localDb.saveRecord(record);
      }

      if (user == null) {
        return records;
      }

      return records.where((record) => record.petId == petId).toList();
    } catch (e) {
      AppLogger.e('RecordsRepo', 'Failed to fetch records from Supabase', e);
      // Fallback to local database
      return await localDb.getRecordsForPet(petId);
    }
  }

  /// Get all records
  Future<List<Record>> getAllRecords() async {
    try {
      // Try to fetch from Supabase first
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Get records for user's pets
      final response = await supabase
          .from('records')
          .select('''
              *,
              pets!inner(owner_id)
            ''')
          .eq('pets.owner_id', user.id)
          .order('at', ascending: false);

        final records = (response as List)
            .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
            .toList();

        // Cache locally
        for (final record in records) {
          await localDb.saveRecord(record);
        }

        return records;
      }
    } catch (e) {
      AppLogger.e('RecordsRepo', 'Failed to fetch records from Supabase', e);
    }

    // Fallback to local database (사용자 기준 필터링)
    final all = await localDb.getAllRecords();
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return all.where((r) => false).toList();
    // 로컬에는 ownerId가 없으므로, 현재는 전체 레코드 중 서버에서 동기화된 항목만 남도록 서버 우선으로 로드하도록 유도
    return all; // 최소 변경: 필요 시 Record 모델에 ownerId 추가 후 강제 필터링
  }

  /// Get today's records
  Future<List<Record>> getTodaysRecords() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('records')
            .select('''
              *,
              pets!inner(owner_id)
            ''')
            .eq('pets.owner_id', user.id)
            .gte('at', startOfDay.toIso8601String())
            .lt('at', endOfDay.toIso8601String())
            .order('at', ascending: false);

        return (response as List)
            .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('RecordsRepo', 'Failed to fetch today\'s records from Supabase', e);
    }

    // Fallback to filtering local records
    final allRecords = await localDb.getAllRecords();
    return allRecords.where((record) {
      return record.at.isAfter(startOfDay) && record.at.isBefore(endOfDay);
    }).toList();
  }

  /// Create a new record
  Future<Record> createRecord(Record record) async {
    // If petId is not a UUID (likely local only), save locally only
    if (!_isValidUUID(record.petId)) {
      AppLogger.w(tag, 'PetId is not a UUID, saving locally only: ${record.petId}');
      await localDb.saveRecord(record);
      return record;
    }

    return saveWithCloudFallback<Record>(
      operationName: 'createRecord',
      cloudAction: () async {
        final insertRow = _toSupabaseRow(record);
        final response = await supabase
            .from('records')
            .insert(insertRow)
            .select()
            .single();

        final savedRecord = _fromSupabaseRow(response as Map<String, dynamic>);
        await localDb.saveRecord(savedRecord);
        return savedRecord;
      },
      localSave: () => localDb.saveRecord(record),
      fallbackValue: record,
    );
  }

  /// Update an existing record
  Future<Record> updateRecord(Record record) async {
    // If petId is not a UUID (likely local only), save locally only
    if (!_isValidUUID(record.petId)) {
      AppLogger.w(tag, 'PetId is not a UUID, updating locally only: ${record.petId}');
      await localDb.saveRecord(record);
      return record;
    }

    return saveWithCloudFallback<Record>(
      operationName: 'updateRecord',
      cloudAction: () async {
        final updateRow = _toSupabaseRow(record);
        final response = await supabase
            .from('records')
            .update(updateRow)
            .eq('id', record.id)
            .select()
            .single();

        final updatedRecord = _fromSupabaseRow(response as Map<String, dynamic>);
        await localDb.saveRecord(updatedRecord);
        return updatedRecord;
      },
      localSave: () => localDb.saveRecord(record),
      fallbackValue: record,
    );
  }

  /// Delete a record
  Future<void> deleteRecord(String id) async {
    return deleteWithCloudFallback(
      operationName: 'deleteRecord',
      cloudAction: () => supabase.from('records').delete().eq('id', id),
      localDelete: () => localDb.deleteRecord(id),
    );
  }

  /// Get records by type
  Future<List<Record>> getRecordsByType(String type) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('records')
            .select('''
              *,
              pets!inner(owner_id)
            ''')
            .eq('pets.owner_id', user.id)
            .eq('type', type)
            .order('at', ascending: false);

        return (response as List)
            .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.e('RecordsRepo', 'Failed to fetch records by type from Supabase', e);
    }

    // Fallback to filtering local records
    final allRecords = await localDb.getAllRecords();
    return allRecords.where((record) => record.type == type).toList();
  }

  /// Sync local changes to Supabase
  Future<void> syncToCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // TODO: Implement conflict resolution and sync logic
      AppLogger.d('RecordsRepo', 'Syncing records to cloud...');
    } catch (e) {
      AppLogger.e('RecordsRepo', 'Failed to sync records to cloud', e);
    }
  }
}

/// Provider for records repository
final recordsRepositoryProvider = Provider<RecordsRepository>((ref) {
  return RecordsRepository(
    supabase: Supabase.instance.client,
    localDb: LocalDatabase.instance,
  );
});
