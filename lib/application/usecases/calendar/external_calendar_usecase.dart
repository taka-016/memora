import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';

class ExternalCalendarUsecase {
  ExternalCalendarUsecase(this._auth, this._storage, this._query);
  final ExternalCalendarAuthService _auth;
  final ExternalCalendarSettingsStorage _storage;
  final ExternalCalendarQueryService _query;

  Future<ExternalCalendarConnection?> restore(String ownerId) =>
      _storage.load(ownerId);

  Future<ExternalCalendarConnection> connect(String ownerId) async {
    final previous = await _storage.load(ownerId);
    final account = await _auth.connect();
    final connection = ExternalCalendarConnection(
      account: account,
      calendarIds: previous?.account.id == account.id ? previous!.calendarIds : const {},
    );
    await _storage.save(ownerId, connection);
    return connection;
  }

  Future<ExternalCalendarConnection> select(
    String ownerId,
    ExternalCalendarConnection connection,
    Set<String> ids,
  ) async {
    final next = ExternalCalendarConnection(
      account: connection.account,
      calendarIds: ids,
    );
    await _storage.save(ownerId, next);
    return next;
  }

  Future<void> disconnect(String ownerId) async {
    try {
      await _storage.remove(ownerId);
    } finally {
      await _auth.disconnect();
    }
  }

  Future<List<ExternalCalendarDto>> calendars(String accountId) =>
      _query.calendars(accountId);
  Future<List<ExternalCalendarEventDto>> events(
    String accountId,
    List<ExternalCalendarDto> calendars,
    DateTime from,
    DateTime to,
  ) => _query.events(accountId, calendars, from, to);
}
