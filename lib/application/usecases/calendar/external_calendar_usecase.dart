import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/device_calendar_access_service.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';

class ExternalCalendarUsecase {
  ExternalCalendarUsecase(this._access, this._storage, this._query);
  final DeviceCalendarAccessService _access;
  final ExternalCalendarSettingsStorage _storage;
  final ExternalCalendarQueryService _query;

  Future<bool> hasReadPermission() => _access.hasReadPermission();
  Stream<void> get changes => _query.changes;

  Future<List<ExternalCalendarConnection>> restore(String ownerId) async {
    final accounts = await _query.accounts();
    final saved = await _storage.load(ownerId);
    return [
      for (final account in accounts)
        ExternalCalendarConnection(
          account: account,
          calendarIds:
              saved
                  .where((v) => v.account.id == account.id)
                  .firstOrNull
                  ?.calendarIds ??
              const {},
        ),
    ];
  }

  Future<List<ExternalCalendarConnection>> requestAccess(String ownerId) async {
    if (!await _access.requestReadPermission()) {
      throw const ExternalCalendarException(ExternalCalendarFailure.permission);
    }
    return restore(ownerId);
  }

  Future<ExternalCalendarConnection> select(
    String ownerId,
    ExternalCalendarConnection connection,
    Set<String> ids,
  ) async {
    final saved = await _storage.load(ownerId);
    final next = ExternalCalendarConnection(
      account: connection.account,
      calendarIds: ids,
    );
    await _storage.save(ownerId, [
      for (final entry in saved)
        if (entry.account.id == connection.account.id) next else entry,
      if (!saved.any((v) => v.account.id == connection.account.id)) next,
    ]);
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
