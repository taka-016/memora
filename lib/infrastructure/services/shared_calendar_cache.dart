import 'dart:convert';
import 'dart:io';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_widget_group_data.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/local_calendar_widget_lock.dart';
import 'package:path_provider/path_provider.dart';

class SharedCalendarCache {
  SharedCalendarCache({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory,
      _lock = LocalCalendarWidgetLock(directory: directory);

  final Future<Directory> Function() _directory;
  final LocalCalendarWidgetLock _lock;

  Future<List<CalendarEventDto>?> loadEvents(
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
  ) async {
    try {
      return _events(
        await _read(await _file(ownerId, groupId)),
        groupId,
        period,
      );
    } catch (_) {
      return null;
    }
  }

  Future<CalendarWidgetGroupData> loadGroup(
    String ownerId,
    String groupId,
    List<CalendarEventPeriod> periods,
  ) async {
    try {
      final file = await _file(ownerId, groupId);
      final modifiedAt = await _lastModified(file);
      final data = await _read(file);
      return CalendarWidgetGroupData(
        eventsByPeriod: {
          for (final period in periods)
            if (_events(data, groupId, period) case final events?)
              period: events,
        },
        labels: _labels(data, groupId),
        labelsObservedAt: _observedAt(data['labels']),
        observedAt: {
          for (final period in periods)
            if (_observedAt(_eventRow(data, period)) case final at when at > 0)
              period: at,
        },
        sourceFiles: {file.path: modifiedAt},
      );
    } catch (_) {
      return const CalendarWidgetGroupData(eventsByPeriod: {}, labels: null);
    }
  }

  Future<void> invalidateEvents(String ownerId, String groupId) =>
      _update(ownerId, groupId, (data) {
        data.remove('events');
        data['invalidatedAt'] = DateTime.now().microsecondsSinceEpoch;
        return true;
      });

  static dynamic _eventRow(
    Map<String, dynamic> data,
    CalendarEventPeriod period,
  ) {
    final rows = data['events'];
    return rows is Map ? rows[_periodKey(period)] : null;
  }

  static List<CalendarEventDto>? _events(
    Map<String, dynamic> data,
    String groupId,
    CalendarEventPeriod period,
  ) {
    try {
      final events = _eventRow(data, period)?['data'];
      if (events is! List) return null;
      return events.map((value) => _event(value, groupId)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEvents(
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
    List<CalendarEventDto> events, {
    int? observedAt,
  }) => _update(ownerId, groupId, (data) {
    final timestamp = observedAt ?? DateTime.now().microsecondsSinceEpoch;
    final key = _periodKey(period);
    final saved = data['events'];
    final rows = saved is Map<String, dynamic> ? saved : <String, dynamic>{};
    final invalidatedAt = data['invalidatedAt'];
    if (_observedAt(rows[key]) > timestamp ||
        (invalidatedAt is int && invalidatedAt > timestamp)) {
      return false;
    }
    rows[key] = {
      'observedAt': timestamp,
      'data': events.map(_encodeEvent).toList(),
    };
    final keys = rows.keys.toList()
      ..sort((a, b) => _observedAt(rows[b]).compareTo(_observedAt(rows[a])));
    data['events'] = {for (final key in keys.take(16)) key: rows[key]};
    return true;
  });

  static String _periodKey(CalendarEventPeriod period) =>
      '${period.from.microsecondsSinceEpoch}:${period.to.microsecondsSinceEpoch}';

  static int _observedAt(dynamic entry) =>
      entry is Map && entry['observedAt'] is int
      ? entry['observedAt'] as int
      : 0;

  Future<List<CalendarLabelDto>?> loadLabels(
    String ownerId,
    String groupId,
  ) async {
    try {
      return _labels(await _read(await _file(ownerId, groupId)), groupId);
    } catch (_) {
      return null;
    }
  }

  static List<CalendarLabelDto>? _labels(
    Map<String, dynamic> data,
    String groupId,
  ) {
    try {
      final labels = data['labels']?['data'];
      if (labels is! List) return null;
      return labels.map((value) {
        final row = value as Map<String, dynamic>;
        return CalendarLabelDto(
          id: row['id'] as String,
          groupId: groupId,
          name: row['name'] as String,
          color: row['color'] as String,
          textColor: row['textColor'] as String,
          sortOrder: row['sortOrder'] as int,
          version: row['version'] as int?,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLabels(
    String ownerId,
    String groupId,
    List<CalendarLabelDto> labels, {
    required int observedAt,
  }) => _update(ownerId, groupId, (data) {
    if (_observedAt(data['labels']) > observedAt) return false;
    data['labels'] = {
      'observedAt': observedAt,
      'data': [
        for (final label in labels)
          {
            'id': label.id,
            'name': label.name,
            'color': label.color,
            'textColor': label.textColor,
            'sortOrder': label.sortOrder,
            'version': label.version,
          },
      ],
    };
    return true;
  });

  Future<File> _file(String ownerId, String groupId) async {
    final directory = await _directory();
    final key = base64Url.encode(utf8.encode(jsonEncode([ownerId, groupId])));
    return File('${directory.path}/calendar_cache_v1/$key.json');
  }

  Future<Map<String, dynamic>> _read(File file) async {
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<int> _lastModified(File file) async {
    try {
      return (await file.lastModified()).millisecondsSinceEpoch;
    } on FileSystemException {
      return 0;
    }
  }

  Future<void> _update(
    String ownerId,
    String groupId,
    bool Function(Map<String, dynamic>) update,
  ) async {
    try {
      await _lock.run('shared_cache', () async {
        final file = await _file(ownerId, groupId);
        final data = await _read(file);
        if (!update(data)) return;
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(jsonEncode(data), flush: true);
        final current = await _lastModified(file);
        if (await _lastModified(temporary) <= current) {
          await temporary.setLastModified(
            DateTime.fromMillisecondsSinceEpoch(current + 1),
          );
        }
        await temporary.rename(file.path);
      });
    } catch (error, stackTrace) {
      logger.w(
        'カレンダーの共有キャッシュを保存できませんでした',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Map<String, Object?> _encodeEvent(CalendarEventDto event) => {
    'id': event.id,
    'version': event.version,
    'title': event.title,
    'start': event.startDateTime.microsecondsSinceEpoch,
    'end': event.endDateTime.microsecondsSinceEpoch,
    'allDay': event.isAllDay,
    'labelId': event.labelId,
    'labelType': event.labelType,
    'memberId': event.memberId,
    'url': event.url,
    'memo': event.memo,
    'locationName': event.locationName,
    'latitude': event.latitude,
    'longitude': event.longitude,
    'notifications': event.notificationMinutesBefore,
    'recurrenceRule': event.recurrenceRule,
    'timeZone': event.timeZone,
    'overrides': [
      for (final override in event.overrides)
        override.originalStartDateTime.microsecondsSinceEpoch,
    ],
  };

  static CalendarEventDto _event(dynamic value, String groupId) {
    final row = value as Map<String, dynamic>;
    final allDay = row['allDay'] as bool;
    DateTime date(dynamic value) =>
        DateTime.fromMicrosecondsSinceEpoch(value as int, isUtc: allDay);
    return CalendarEventDto(
      id: row['id'] as String,
      groupId: groupId,
      version: row['version'] as int?,
      title: row['title'] as String,
      startDateTime: date(row['start']),
      endDateTime: date(row['end']),
      isAllDay: allDay,
      labelId: row['labelId'] as String,
      labelType: row['labelType'] as String,
      memberId: row['memberId'] as String,
      url: row['url'] as String,
      memo: row['memo'] as String,
      locationName: row['locationName'] as String,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      notificationMinutesBefore: (row['notifications'] as List).cast<int>(),
      recurrenceRule: row['recurrenceRule'] as String?,
      timeZone: row['timeZone'] as String?,
      overrides: [
        for (final value in row['overrides'] as List)
          CalendarEventOverride(originalStartDateTime: date(value)),
      ],
    );
  }
}
