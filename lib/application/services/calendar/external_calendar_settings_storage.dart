import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';

abstract class ExternalCalendarSettingsStorage {
  Future<ExternalCalendarConnection?> load(String ownerId);
  Future<void> save(String ownerId, ExternalCalendarConnection connection);
  Future<void> remove(String ownerId);
}
