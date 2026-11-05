import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';

abstract class ExternalCalendarSettingsStorage {
  Future<List<ExternalCalendarConnection>> load(String ownerId);
  Future<void> save(
    String ownerId,
    List<ExternalCalendarConnection> connections,
  );
  Future<void> remove(String ownerId);
}
