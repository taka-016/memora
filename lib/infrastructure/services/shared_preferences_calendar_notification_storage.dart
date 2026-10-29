import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/domain/entities/calendar/calendar_notifications.dart';

class SharedPreferencesCalendarNotificationStorage
    implements CalendarNotificationStorage {
  const SharedPreferencesCalendarNotificationStorage();
  static const _key = 'calendar_notification_preferences';
  @override
  Future<CalendarNotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return const CalendarNotificationPreferences();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return CalendarNotificationPreferences(
      allDayMinuteOfDay: data['minute'] as int,
      allDay: (data['allDay'] as List).cast<int>(),
      timed: (data['timed'] as List).cast<int>(),
    );
  }

  @override
  Future<void> save(CalendarNotificationPreferences value) async {
    validateCalendarNotifications(value.allDay, true);
    validateCalendarNotifications(value.timed, false);
    if (value.allDayMinuteOfDay < 0 || value.allDayMinuteOfDay >= 1440)
      throw ArgumentError('基準時刻が不正です');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _key,
      jsonEncode({
        'minute': value.allDayMinuteOfDay,
        'allDay': value.allDay,
        'timed': value.timed,
      }),
    )) {
      throw StateError('通知設定を保存できませんでした');
    }
  }
}
