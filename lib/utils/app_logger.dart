import 'package:flutter/foundation.dart';

/// 앱 전체 로깅 유틸리티
/// kDebugMode에서만 로그를 출력하여 릴리스 빌드에서 불필요한 출력 방지
class AppLogger {
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) {
        debugPrint('[$tag] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$tag] StackTrace: $stackTrace');
      }
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] WARN: $message');
    }
  }
}
