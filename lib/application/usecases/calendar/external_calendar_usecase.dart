import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';

class ExternalCalendarUsecase {
  ExternalCalendarUsecase(this._auth, this._storage, this._query);
  final ExternalCalendarAuthService _auth;
  final ExternalCalendarSettingsStorage _storage;
  final ExternalCalendarQueryService _query;

  Future<List<ExternalCalendarConnection>> restore(String ownerId) async {
    final connections = await _storage.load(ownerId);
    _auth.restoreAccounts(connections.map((v) => v.account));
    return connections;
  }

  Future<List<ExternalCalendarConnection>> connect(String ownerId) async {
    final previous = await restore(ownerId);
    final account = await _auth.connect();
    final existing = previous
        .where((v) => v.account.id == account.id)
        .firstOrNull;
    final connection = ExternalCalendarConnection(
      account: account,
      calendarIds: existing?.calendarIds ?? const {},
    );
    final next = [
      for (final entry in previous)
        if (entry.account.id == account.id) connection else entry,
      if (existing == null) connection,
    ];
    await _storage.save(ownerId, next);
    return next;
  }

  Future<List<ExternalCalendarConnection>> select(
    String ownerId,
    ExternalCalendarConnection connection,
    Set<String> ids,
  ) async {
    final previous = await _storage.load(ownerId);
    final next = [
      for (final entry in previous)
        if (entry.account.id == connection.account.id)
          ExternalCalendarConnection(
            account: connection.account,
            calendarIds: ids,
          )
        else
          entry,
    ];
    await _storage.save(ownerId, next);
    return next;
  }

  Future<List<ExternalCalendarConnection>> disconnect(
    String ownerId,
    String accountId,
  ) async {
    final previous = await _storage.load(ownerId);
    final next = previous.where((v) => v.account.id != accountId).toList();
    if (next.isEmpty) {
      await _storage.remove(ownerId);
    } else {
      await _storage.save(ownerId, next);
    }
    await _auth.disconnect(accountId);
    return next;
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
