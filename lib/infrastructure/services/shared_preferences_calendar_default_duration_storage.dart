import 'package:memora/application/services/calendar_default_duration_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCalendarDefaultDurationStorage
    implements CalendarDefaultDurationStorage {
  const SharedPreferencesCalendarDefaultDurationStorage();
  static const _key = 'calendar_default_duration_minutes';
  @override
  Future<int> load() async {
    final preferences = await SharedPreferences.getInstance();
    final minutes = preferences.getInt(_key) ?? 60;
    if (minutes < 1 || minutes > 1440) {
      throw const FormatException('予定の標準時間が不正です');
    }
    return minutes;
  }

  @override
  Future<void> save(int minutes) async {
    if (minutes < 1 || minutes > 1440) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setInt(_key, minutes)) {
      throw StateError('予定の標準時間を保存できませんでした');
    }
  }
}
