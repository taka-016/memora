import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_display_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('初期値は日曜始まりで六曜を非表示にし保存した設定を復元する', () async {
    const storage = SharedPreferencesCalendarDisplaySettingsStorage();
    expect(await storage.load(), const CalendarDisplaySettings());
    const selected = CalendarDisplaySettings(
      weekStart: CalendarWeekStart.monday,
      showRokuyo: true,
    );
    await storage.save(selected);
    expect(
      await const SharedPreferencesCalendarDisplaySettingsStorage().load(),
      selected,
    );
    await storage.save(selected.copyWith(showRokuyo: false));
    expect((await storage.load()).weekStart, CalendarWeekStart.monday);
    expect((await storage.load()).showRokuyo, isFalse);
  });
}
