import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/calendar_display_settings_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_display_settings_storage.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

final calendarDisplaySettingsStorageProvider =
    Provider<CalendarDisplaySettingsStorage>(
      (ref) => const SharedPreferencesCalendarDisplaySettingsStorage(),
    );

final updateCalendarWidgetAppearanceProvider =
    Provider<Future<void> Function()>(
      (ref) => const HomeWidgetCalendarCacheStorage().update,
    );
