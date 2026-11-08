import 'dart:convert';

import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/application/services/calendar_display_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCalendarDisplaySettingsStorage
    implements CalendarDisplaySettingsStorage {
  const SharedPreferencesCalendarDisplaySettingsStorage();

  static const _key = 'calendar_display_settings';

  @override
  Future<CalendarDisplaySettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return const CalendarDisplaySettings();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return CalendarDisplaySettings(
      weekStart: data['weekStart'] == 'monday'
          ? CalendarWeekStart.monday
          : CalendarWeekStart.sunday,
      showRokuyo: data['showRokuyo'] == true,
    );
  }

  @override
  Future<void> save(CalendarDisplaySettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key,
      jsonEncode({
        'weekStart': settings.weekStart.name,
        'showRokuyo': settings.showRokuyo,
      }),
    );
    if (!saved) throw StateError('カレンダーの表示設定を保存できませんでした');
  }
}
