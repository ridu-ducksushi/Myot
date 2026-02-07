import 'package:flutter/foundation.dart';
import 'package:petcare/data/local/database.dart';
import 'package:petcare/utils/app_logger.dart';

/// Bootstrap the application with necessary initializations
class AppBootstrap {
  static bool _initialized = false;

  /// Initialize the app with required services
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local database
      await LocalDatabase.initialize();
      
      AppLogger.d('Bootstrap', 'Local database initialized');

      _initialized = true;
      
      AppLogger.d('Bootstrap', 'App bootstrap completed successfully');
    } catch (e) {
      AppLogger.e('Bootstrap', 'App bootstrap failed', e);
      rethrow;
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    if (!_initialized) return;

    try {
      await LocalDatabase.instance.close();
      
      AppLogger.d('Bootstrap', 'App cleanup completed');
    } catch (e) {
      AppLogger.e('Bootstrap', 'App cleanup failed', e);
    }
  }
}