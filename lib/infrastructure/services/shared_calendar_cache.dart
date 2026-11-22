import 'dart:convert';
import 'dart:io';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_event_slice.dart';
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

  Future<({List<CalendarEventSlice> slices, List<CalendarEventPeriod> missing})>
  loadEvents(String ownerId, String groupId, CalendarEventPeriod period) async {
    final data = await _read(ownerId, groupId);
    final slices = <CalendarEventSlice>[];
    final missing = <CalendarEventPeriod>[];
    var cursor = period.from;
    try {
      for (final entry in data['events'] as List? ?? const []) {
        final row = entry as Map<String, dynamic>;
        final bounds = _period(row);
        final from = bounds.from.isAfter(cursor) ? bounds.from : cursor;
        final to = bounds.to.isBefore(period.to) ? bounds.to : period.to;
        if (!from.isBefore(to)) continue;
        if (cursor.isBefore(from)) {
          missing.add(CalendarEventPeriod(from: cursor, to: from));
        }
        slices.add(
          CalendarEventSlice(
            CalendarEventPeriod(from: from, to: to),
            (row['data'] as List).map((v) => _event(v, groupId)).toList(),
          ),
        );
        cursor = to;
      }
    } catch (_) {
      return (slices: <CalendarEventSlice>[], missing: [period]);
    }
    if (cursor.isBefore(period.to)) {
      missing.add(CalendarEventPeriod(from: cursor, to: period.to));
    }
    return (slices: slices, missing: missing);
  }

  Future<void> saveEvents(
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
    List<CalendarEventDto> events, {
    int? observedAt,
  }) => _update(ownerId, groupId, (data) {
    final timestamp = observedAt ?? DateTime.now().microsecondsSinceEpoch;
    final rows = <Map<String, dynamic>>[];
    var incoming = [period];
    for (final entry in data['events'] as List? ?? const []) {
      final row = entry as Map<String, dynamic>;
      final bounds = _period(row);
      if ((row['observedAt'] as int) > timestamp) {
        incoming = [for (final part in incoming) ..._subtract(part, bounds)];
        rows.add(row);
      } else {
        rows.addAll([
          for (final part in _subtract(bounds, period))
            {...row, ..._bounds(part)},
        ]);
      }
    }
    final encoded = events.map(_encodeEvent).toList();
    rows.addAll([
      for (final part in incoming)
        {..._bounds(part), 'observedAt': timestamp, 'data': encoded},
    ]);
    rows.sort(
      (a, b) => (b['observedAt'] as int).compareTo(a['observedAt'] as int),
    );
    data['events'] = rows.take(32).toList()
      ..sort((a, b) => _period(a).from.compareTo(_period(b).from));
  });

  Future<List<CalendarLabelDto>?> loadLabels(
    String ownerId,
    String groupId,
  ) async {
    final data = await _read(ownerId, groupId);
    final labels = data['labels']?['data'];
    if (labels is! List) return null;
    try {
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
    if ((data['labels']?['observedAt'] as int? ?? 0) > observedAt) return;
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
  });

  Future<File> _file(String ownerId, String groupId) async {
    final directory = await _directory();
    final key = base64Url.encode(utf8.encode(jsonEncode([ownerId, groupId])));
    return File('${directory.path}/calendar_cache_v1/$key.json');
  }

  Future<Map<String, dynamic>> _read(String ownerId, String groupId) async {
    try {
      final file = await _file(ownerId, groupId);
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _update(
    String ownerId,
    String groupId,
    void Function(Map<String, dynamic>) update,
  ) async {
    try {
      await _lock.run('shared_cache', () async {
        final file = await _file(ownerId, groupId);
        final data = await _read(ownerId, groupId);
        update(data);
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(jsonEncode(data), flush: true);
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

  static CalendarEventPeriod _period(Map<String, dynamic> row) =>
      CalendarEventPeriod(
        from: DateTime.parse(row['from'] as String),
        to: DateTime.parse(row['to'] as String),
      );

  static Map<String, String> _bounds(CalendarEventPeriod period) => {
    'from': period.from.toIso8601String(),
    'to': period.to.toIso8601String(),
  };

  static Iterable<CalendarEventPeriod> _subtract(
    CalendarEventPeriod period,
    CalendarEventPeriod removed,
  ) sync* {
    if (!period.from.isBefore(removed.to) ||
        !removed.from.isBefore(period.to)) {
      yield period;
      return;
    }
    if (period.from.isBefore(removed.from)) {
      yield CalendarEventPeriod(from: period.from, to: removed.from);
    }
    if (removed.to.isBefore(period.to)) {
      yield CalendarEventPeriod(from: removed.to, to: period.to);
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
