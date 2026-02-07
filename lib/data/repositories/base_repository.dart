import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/utils/app_logger.dart';

/// 기본 Repository 클래스
/// 클라우드 우선, 로컬 폴백 패턴을 공통화
abstract class BaseRepository {
  BaseRepository({
    required this.supabase,
    required this.localDb,
  });

  final SupabaseClient supabase;
  final LocalDatabase localDb;

  /// 서브클래스에서 로깅용 태그 정의
  String get tag;

  /// 클라우드 작업 시도 후 실패 시 로컬 폴백 실행
  Future<R> withCloudFallback<R>({
    required Future<R> Function() cloudAction,
    required Future<R> Function() localFallback,
    required String operationName,
  }) async {
    try {
      return await cloudAction();
    } catch (e) {
      AppLogger.e(tag, '$operationName 실패, 로컬 폴백 사용', e);
      return await localFallback();
    }
  }

  /// 클라우드 작업 시도 후 실패 시 로컬에 저장하고 원본 반환
  Future<T> saveWithCloudFallback<T>({
    required Future<T> Function() cloudAction,
    required Future<void> Function() localSave,
    required T fallbackValue,
    required String operationName,
  }) async {
    try {
      return await cloudAction();
    } catch (e) {
      AppLogger.e(tag, '$operationName 실패, 로컬 저장', e);
      await localSave();
      return fallbackValue;
    }
  }

  /// 클라우드 삭제 시도 후 실패해도 로컬 삭제 실행
  Future<void> deleteWithCloudFallback({
    required Future<void> Function() cloudAction,
    required Future<void> Function() localDelete,
    required String operationName,
  }) async {
    try {
      await cloudAction();
      await localDelete();
    } catch (e) {
      AppLogger.e(tag, '$operationName 실패', e);
      await localDelete();
    }
  }
}
