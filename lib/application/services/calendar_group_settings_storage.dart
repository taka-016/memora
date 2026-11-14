import 'package:memora/application/models/calendar_group_settings.dart';

abstract class CalendarGroupSettingsStorage {
  Future<CalendarGroupSettings> load(String ownerId);
  Future<void> save(String ownerId, CalendarGroupSettings settings);
}
