import 'package:flutter/services.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/device_calendar_access_service.dart';

class MethodChannelDeviceCalendarService
    implements DeviceCalendarAccessService, ExternalCalendarQueryService {
  const MethodChannelDeviceCalendarService({
    MethodChannel channel = const MethodChannel('memora/device_calendar'),
    EventChannel eventsChannel = const EventChannel(
      'memora/device_calendar_changes',
    ),
  }) : _channel = channel,
       _eventsChannel = eventsChannel;

  final MethodChannel _channel;
  final EventChannel _eventsChannel;

  Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw ExternalCalendarException(
        error.code == 'calendar_permission_denied'
            ? ExternalCalendarFailure.permission
            : ExternalCalendarFailure.unavailable,
      );
    } on MissingPluginException {
      throw const ExternalCalendarException(
        ExternalCalendarFailure.unavailable,
      );
    }
  }

  @override
  Stream<void> get changes =>
      _eventsChannel.receiveBroadcastStream().map<void>((_) {});
  @override
  Future<bool> hasReadPermission() async =>
      await _call<bool>('hasReadPermission') ?? false;
  @override
  Future<bool> requestReadPermission() async =>
      await _call<bool>('requestReadPermission') ?? false;

  Future<List<Map<Object?, Object?>>> _calendars() async =>
      (await _call<List<dynamic>>('calendars') ?? [])
          .cast<Map<Object?, Object?>>();

  @override
  Future<List<ExternalCalendarAccount>> accounts() async {
    final rows = await _calendars();
    return {
      for (final row in rows)
        row['accountId'] as String: ExternalCalendarAccount(
          id: row['accountId'] as String,
          name: row['accountName'] as String,
        ),
    }.values.toList();
  }

  @override
  Future<List<ExternalCalendarDto>> calendars(String accountId) async => [
    for (final row in await _calendars())
      if (row['accountId'] == accountId)
        ExternalCalendarDto(
          id: row['id'] as String,
          name: row['name'] as String,
        ),
  ];

  @override
  Future<List<ExternalCalendarEventDto>> events(
    String accountId,
    List<ExternalCalendarDto> calendars,
    DateTime from,
    DateTime to,
  ) async {
    if (calendars.isEmpty) return [];
    final rows =
        await _call<List<dynamic>>('events', {
          'calendarIds': calendars.map((v) => v.id).toList(),
          'from': from.millisecondsSinceEpoch,
          'to': to.millisecondsSinceEpoch,
        }) ??
        [];
    return [
      for (final value in rows)
        _event(accountId, calendars, value as Map<Object?, Object?>),
    ];
  }

  ExternalCalendarEventDto _event(
    String accountId,
    List<ExternalCalendarDto> calendars,
    Map<Object?, Object?> data,
  ) {
    final allDay = data['allDay'] as bool;
    final end = DateTime.fromMillisecondsSinceEpoch(
      data['end'] as int,
      isUtc: true,
    );
    final rules = (data['recurrence'] as List? ?? []).cast<String>();
    return ExternalCalendarEventDto(
      accountId: accountId,
      id: data['id'] as String,
      calendarId: data['calendarId'] as String,
      calendarName: calendars
          .firstWhere((v) => v.id == data['calendarId'])
          .name,
      title: (data['title'] as String?)?.isNotEmpty == true
          ? data['title'] as String
          : '予定あり',
      startDateTime: DateTime.fromMillisecondsSinceEpoch(
        data['begin'] as int,
        isUtc: true,
      ),
      endDateTime: allDay ? end.subtract(const Duration(days: 1)) : end,
      isAllDay: allDay,
      memo: data['description'] as String? ?? '',
      locationName: data['location'] as String? ?? '',
      isRecurring: rules.isNotEmpty || data['isRecurring'] == true,
      recurrence: List.unmodifiable(rules),
      timeZone: data['timeZone'] as String?,
    );
  }
}
