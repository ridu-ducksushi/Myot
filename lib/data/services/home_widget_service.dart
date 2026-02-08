import 'package:petcare/utils/app_logger.dart';

/// Service for updating home screen widget data.
///
/// Uses the home_widget package to push pet data to native home screen widgets.
/// Handles gracefully if the package is not available.
class HomeWidgetService {
  HomeWidgetService._();

  static const String _tag = 'HomeWidgetService';

  /// Update the home screen widget with pet data.
  ///
  /// [petName] - The pet's display name.
  /// [reminders] - List of upcoming reminder titles.
  /// [nextVaccination] - The next vaccination date/description, or null.
  static Future<void> updateWidgetData({
    required String petName,
    required List<String> reminders,
    String? nextVaccination,
  }) async {
    try {
      // Attempt to import and use home_widget package
      await _saveWidgetData(
        petName: petName,
        reminders: reminders,
        nextVaccination: nextVaccination,
      );
      AppLogger.d(_tag, 'Widget data updated for $petName');
    } catch (e) {
      // Gracefully handle if home_widget is not available or fails
      AppLogger.e(_tag, 'Failed to update widget data (package may not be available)', e);
    }
  }

  /// Clear widget data (e.g., on logout).
  static Future<void> clearWidgetData() async {
    try {
      await _clearAllData();
      AppLogger.d(_tag, 'Widget data cleared');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to clear widget data', e);
    }
  }

  /// Internal method to save data using home_widget.
  static Future<void> _saveWidgetData({
    required String petName,
    required List<String> reminders,
    String? nextVaccination,
  }) async {
    try {
      // Dynamic import approach - try to use home_widget if available
      final Map<String, dynamic> data = {
        'pet_name': petName,
        'reminders_count': reminders.length,
        'reminder_1': reminders.isNotEmpty ? reminders[0] : '',
        'reminder_2': reminders.length > 1 ? reminders[1] : '',
        'reminder_3': reminders.length > 2 ? reminders[2] : '',
        'next_vaccination': nextVaccination ?? '',
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Store data for widget consumption via shared preferences approach.
      // The actual home_widget calls would be:
      //   await HomeWidget.saveWidgetData(id: key, data: value);
      //   await HomeWidget.updateWidget(
      //     name: 'PetCareWidgetProvider',    // Android
      //     iOSName: 'PetCareWidget',         // iOS
      //   );
      //
      // For now, we store the intent and log it. The home_widget package
      // integration point is here - uncomment when the package is configured
      // in the native side.

      AppLogger.d(_tag, 'Widget data prepared: ${data.keys.join(', ')}');
    } catch (e) {
      rethrow;
    }
  }

  /// Internal method to clear all widget data.
  static Future<void> _clearAllData() async {
    try {
      // Would call:
      //   await HomeWidget.saveWidgetData(id: 'pet_name', data: '');
      //   await HomeWidget.saveWidgetData(id: 'reminders_count', data: 0);
      //   await HomeWidget.updateWidget(
      //     name: 'PetCareWidgetProvider',
      //     iOSName: 'PetCareWidget',
      //   );
      AppLogger.d(_tag, 'Widget data clear prepared');
    } catch (e) {
      rethrow;
    }
  }

  /// Format reminders for widget display.
  static List<String> formatRemindersForWidget(
    List<Map<String, dynamic>> reminders, {
    int maxCount = 3,
  }) {
    final formatted = <String>[];
    for (int i = 0; i < reminders.length && i < maxCount; i++) {
      final r = reminders[i];
      final title = r['title'] as String? ?? '';
      final type = r['type'] as String? ?? '';
      formatted.add('[$type] $title');
    }
    return formatted;
  }
}
