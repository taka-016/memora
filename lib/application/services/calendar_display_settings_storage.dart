import 'package:memora/application/models/calendar_display_settings.dart';

abstract interface class CalendarDisplaySettingsStorage {
  Future<CalendarDisplaySettings> load();
  Future<void> save(CalendarDisplaySettings settings);
}
