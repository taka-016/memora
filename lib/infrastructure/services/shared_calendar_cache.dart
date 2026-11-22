import 'dart:convert';
import 'dart:io';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_widget_group_data.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/infrastructure/services/local_calendar_widget_lock.dart';
import 'package:path_provider/path_provider.dart';

typedef CalendarEventCacheChange = ({
  String groupId,
  String eventId,
  CalendarEventDto? event,
  DateTime? recurrenceEnd,
  int? version,
});

class SharedCalendarCache {
  SharedCalendarCache({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory,
      _lock = LocalCalendarWidgetLock(directory: directory);

  final Future<Directory> Function() _directory;
  final LocalCalendarWidgetLock _lock;
  static const _maxCachedMonths = 48;
  static final _expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());

  Future<List<CalendarEventDto>?> loadEvents(
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
  ) async {
    try {
      final data = await _read(await _file(ownerId, groupId));
      return _events(
        data,
        groupId,
        _monthsIn(period).toList(),
        _seriesRows(data, groupId),
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
      final series = _seriesRows(data, groupId);
      return CalendarWidgetGroupData(
        eventsByPeriod: {
          for (final period in periods)
            period: ?_events(data, groupId, [period], series),
        },
        labels: _labels(data, groupId),
        labelsObservedAt: _observedAt(data['labels']),
        observedAt: {
          for (final period in periods)
            if (_observedAt(_singleEventRow(data, period)) case final at
                when at > 0)
              period: at,
        },
        sourceFiles: {file.path: modifiedAt},
      );
    } catch (_) {
      return const CalendarWidgetGroupData(eventsByPeriod: {}, labels: null);
    }
  }

  Future<void> applyEventChanges(
    String ownerId,
    List<CalendarEventCacheChange> changes, {
    required int committedAt,
  }) async {
    for (final groupId in changes.map((change) => change.groupId).toSet()) {
      final groupChanges = changes.where((change) => change.groupId == groupId);
      await _update(ownerId, groupId, (data) {
        final previousCommit = data['eventCommitAt'] as int? ?? 0;
        if (committedAt > previousCommit) data['eventCommitAt'] = committedAt;
        final rows = data['singleEvents'];
        if (rows is! Map<String, dynamic> || rows.isEmpty) {
          return committedAt > previousCommit;
        }
        final commits = _eventCommits(data);
        final applicable = [
          for (final change in groupChanges)
            if ((commits[change.eventId] ?? 0) <= committedAt) change,
        ];
        if (applicable.isEmpty) return committedAt > previousCommit;
        final series = _seriesRows(data, groupId);
        for (final change in applicable) {
          commits[change.eventId] = committedAt;
          final previous = series[change.eventId];
          final event = change.event;
          final previousVersion = previous?.parent.version ?? 0;
          final version = change.version ?? 0;
          if (previousVersion > version) continue;
          final sameVersionObservedLater =
              previous != null &&
              previousVersion == version &&
              previous.observedAt > committedAt;
          if (event == null || event.recurrenceRule == null) {
            if (!sameVersionObservedLater) series.remove(change.eventId);
            continue;
          }

          final current = sameVersionObservedLater
              ? previous
              : _updatedSeries(
                  event,
                  change.recurrenceEnd,
                  committedAt,
                  previous,
                );
          series[change.eventId] = current;
          for (final entry in rows.entries) {
            final month = _parsePeriodKey(entry.key);
            if (month == null || _observedAt(entry.value) > committedAt) {
              continue;
            }
            if (current.overlaps(month)) {
              current.overridesByMonth[entry.key] = _overridesInMonth(
                event,
                month,
              );
            }
          }
        }
        _saveSeriesRows(data, series, rows.keys.toSet());
        data['commits'] = commits;
        for (final entry in rows.entries.toList()) {
          final period = _parsePeriodKey(entry.key);
          final row = entry.value;
          if (period == null ||
              row is! Map<String, dynamic> ||
              _observedAt(row) > committedAt) {
            continue;
          }
          final previous = row['data'];
          if (previous is! List) continue;
          final events = _eventRows(previous);
          var periodChanged = false;
          for (final change in applicable) {
            final existing = events[change.eventId];
            if (((existing?['version'] as int?) ?? 0) > (change.version ?? 0)) {
              continue;
            }
            final event = change.event;
            final monthEvent =
                event != null &&
                    event.recurrenceRule == null &&
                    _overlapsMonth(
                      event,
                      period,
                      event.startDateTime,
                      event.endDateTime,
                    )
                ? event
                : null;
            if (monthEvent != null) {
              final updated = _encodeEvent(monthEvent);
              if (existing == null ||
                  _event(existing, groupId) != _event(updated, groupId)) {
                events[change.eventId] = updated;
                periodChanged = true;
              }
            } else if (events.remove(change.eventId) != null) {
              periodChanged = true;
            }
          }
          if (periodChanged) {
            rows[entry.key] = {...row, 'data': events.values.toList()};
          }
        }
        return true;
      });
    }
  }

  static CalendarEventPeriod? _parsePeriodKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final from = int.tryParse(parts.first);
    final to = int.tryParse(parts.last);
    if (from == null || to == null) return null;
    return CalendarEventPeriod(
      from: DateTime.fromMicrosecondsSinceEpoch(from),
      to: DateTime.fromMicrosecondsSinceEpoch(to),
    );
  }

  static Map<String, int> _eventCommits(Map<String, dynamic> row) {
    final commits = row['commits'];
    return {
      if (commits is Map<String, dynamic>)
        for (final entry in commits.entries)
          if (entry.value is int) entry.key: entry.value as int,
    };
  }

  static Map<String, Map<String, dynamic>> _eventRows(List<dynamic> events) => {
    for (final event in events.whereType<Map<String, dynamic>>())
      if (event['id'] case final String id) id: event,
  };

  static dynamic _singleEventRow(
    Map<String, dynamic> data,
    CalendarEventPeriod period,
  ) {
    final rows = data['singleEvents'];
    return rows is Map ? rows[_periodKey(period)] : null;
  }

  static List<CalendarEventDto>? _events(
    Map<String, dynamic> data,
    String groupId,
    List<CalendarEventPeriod> months,
    Map<String, _CachedSeries> series,
  ) {
    final singleEvents = <String, CalendarEventDto>{};
    final singleEventIdsByMonth = <CalendarEventPeriod, Set<String>>{};
    final observations = <int>{};
    for (final month in months) {
      final row = _singleEventRow(data, month);
      final events = row?['data'];
      if (events is! List) return null;
      final ids = singleEventIdsByMonth[month] = <String>{};
      observations.add(_observedAt(row));
      for (final value in events) {
        final event = _event(value, groupId);
        ids.add(event.id);
        final previous = singleEvents[event.id];
        if (previous == null ||
            (event.version ?? 0) > (previous.version ?? 0)) {
          singleEvents[event.id] = event;
        }
      }
    }
    if (observations.length > 1) {
      for (final event in singleEvents.values) {
        if (singleEventIdsByMonth.entries.any(
          (entry) =>
              !entry.value.contains(event.id) &&
              _overlapsMonth(
                event,
                entry.key,
                event.startDateTime,
                event.endDateTime,
              ),
        )) {
          return null;
        }
      }
    }

    final recurringEvents = <CalendarEventDto>[];
    for (final current in series.values) {
      final overrides = <CalendarEventOverride>{};
      var present = false;
      var absent = false;
      for (final month in months.where(current.overlaps)) {
        final key = _periodKey(month);
        if (!current.overridesByMonth.containsKey(key)) return null;
        final fetched = current.overridesByMonth[key];
        if (fetched == null) {
          absent = true;
        } else {
          present = true;
          overrides.addAll(fetched);
        }
      }
      // 期間全体に対して親予定を展開できる場合だけ、先行表示に使う。
      if (present && absent) return null;
      if (present) {
        if (singleEvents.containsKey(current.parent.id)) return null;
        recurringEvents.add(
          current.parent.copyWith(overrides: overrides.toList()),
        );
      }
    }
    return [...singleEvents.values, ...recurringEvents];
  }

  static Map<String, _CachedSeries> _seriesRows(
    Map<String, dynamic> data,
    String groupId,
  ) {
    final rows = data['series'];
    if (rows is! Map<String, dynamic>) return {};
    return rows.map((id, value) {
      final parent = _event(value['parent'], groupId);
      final end = value['end'] as int?;
      final months = value['months'] as Map<String, dynamic>;
      return MapEntry(
        id,
        _CachedSeries(
          parent,
          end == null ? null : DateTime.fromMicrosecondsSinceEpoch(end),
          _observedAt(value),
          months.map(
            (key, dates) => MapEntry(
              key,
              (dates as List?)
                  ?.map(
                    (date) => CalendarEventOverride(
                      originalStartDateTime:
                          DateTime.fromMicrosecondsSinceEpoch(
                            date as int,
                            isUtc: parent.isAllDay,
                          ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    });
  }

  static void _saveSeriesRows(
    Map<String, dynamic> data,
    Map<String, _CachedSeries> series,
    Set<String> retainedMonths,
  ) {
    data['series'] = {
      for (final entry in series.entries)
        if (entry.value.overridesByMonth.keys.any(retainedMonths.contains))
          entry.key: {
            'parent': _encodeEvent(entry.value.parent),
            'end': entry.value.end?.microsecondsSinceEpoch,
            'observedAt': entry.value.observedAt,
            'months': {
              for (final month in entry.value.overridesByMonth.entries)
                if (retainedMonths.contains(month.key))
                  month.key: month.value
                      ?.map(
                        (override) => override
                            .originalStartDateTime
                            .microsecondsSinceEpoch,
                      )
                      .toList(),
            },
          },
    };
  }

  static _CachedSeries _updatedSeries(
    CalendarEventDto event,
    DateTime? end,
    int observedAt,
    _CachedSeries? previous,
  ) {
    final parent = previous?.parent;
    final sameSchedule =
        parent != null &&
        parent.startDateTime.isAtSameMomentAs(event.startDateTime) &&
        parent.endDateTime.isAtSameMomentAs(event.endDateTime) &&
        parent.recurrenceRule == event.recurrenceRule &&
        parent.timeZone == event.timeZone &&
        parent.isAllDay == event.isAllDay;
    return _CachedSeries(
      event.copyWith(overrides: const []),
      end,
      observedAt,
      sameSchedule ? previous!.overridesByMonth : {},
    );
  }

  static Iterable<CalendarEventPeriod> _monthsIn(
    CalendarEventPeriod period,
  ) sync* {
    for (var start = period.from; start.isBefore(period.to);) {
      final month = CalendarEventPeriod.forCalendarMonth(start);
      yield month;
      start = month.to;
    }
  }

  static bool _overlapsMonth(
    CalendarEventDto event,
    CalendarEventPeriod month,
    DateTime start,
    DateTime? end,
  ) {
    final from = event.isAllDay
        ? DateTime.utc(month.from.year, month.from.month)
        : month.from;
    final to = event.isAllDay
        ? DateTime.utc(month.to.year, month.to.month)
        : month.to;
    return start.isBefore(to) &&
        (end == null ||
            end.isAfter(from) ||
            (event.duration == Duration.zero && end.isAtSameMomentAs(from)));
  }

  static List<CalendarEventOverride> _overridesInMonth(
    CalendarEventDto event,
    CalendarEventPeriod month,
  ) => event.overrides
      .where(
        (override) => _cancellationOverlapsMonth(
          event,
          month,
          override.originalStartDateTime,
        ),
      )
      .toList();

  static bool _cancellationOverlapsMonth(
    CalendarEventDto event,
    CalendarEventPeriod month,
    DateTime start,
  ) => _overlapsMonth(event, month, start, start.add(event.duration));

  static void _invalidateChangedCancellationMonths(
    _CachedSeries series,
    List<DateTime> cancellationStarts,
  ) {
    // 親予定の取消IDに含まれる元の回の日時で、取得済みの月だけを照合する。
    series.overridesByMonth.removeWhere((key, overrides) {
      final month = _parsePeriodKey(key);
      if (month == null || overrides == null) return false;
      final expected = {
        for (final start in cancellationStarts)
          if (_cancellationOverlapsMonth(series.parent, month, start))
            start.microsecondsSinceEpoch,
      };
      return expected.length != overrides.length ||
          overrides.any(
            (override) => !expected.contains(
              override.originalStartDateTime.microsecondsSinceEpoch,
            ),
          );
    });
  }

  Future<bool> saveEvents(
    String ownerId,
    String groupId,
    CalendarEventPeriod period,
    List<CalendarEventDto> events, {
    int? observedAt,
    Map<String, List<DateTime>> cancellationStartsBySeries = const {},
  }) async {
    final singleEvents = events.where((event) => event.recurrenceRule == null);
    final recurringEvents = {
      for (final event in events)
        if (event.recurrenceRule != null) event.id: event,
    };
    var retryInitialFetch = false;
    await _update(ownerId, groupId, (data) {
      final timestamp = observedAt ?? DateTime.now().microsecondsSinceEpoch;
      final saved = data['singleEvents'];
      final rows = saved is Map<String, dynamic> ? saved : <String, dynamic>{};
      final months = _monthsIn(period)
          .where((month) => _observedAt(rows[_periodKey(month)]) <= timestamp)
          .toList();
      if (months.isEmpty) return false;
      if ((data['eventCommitAt'] as int? ?? 0) > timestamp &&
          months.any((month) => rows[_periodKey(month)]?['data'] is! List)) {
        retryInitialFetch = true;
        return false;
      }
      final commits = _eventCommits(data);
      final series = _seriesRows(data, groupId);
      for (final id in {...series.keys, ...recurringEvents.keys}) {
        if ((commits[id] ?? 0) > timestamp) continue;
        final previous = series[id];
        final event = recurringEvents[id];
        if (event == null) {
          if (previous == null || previous.observedAt > timestamp) continue;
          for (final month in months.where(previous.overlaps)) {
            previous.overridesByMonth[_periodKey(month)] = null;
          }
          continue;
        }
        final version = event.version ?? 0;
        final previousVersion = previous?.parent.version ?? 0;
        if (version < previousVersion) continue;
        final current =
            previous == null ||
                version > previousVersion ||
                timestamp >= previous.observedAt
            ? _updatedSeries(
                event,
                _expander.seriesEndDateTime(event),
                timestamp,
                previous,
              )
            : previous;
        series[id] = current;
        final cancellationStarts = cancellationStartsBySeries[id];
        if (cancellationStarts != null) {
          _invalidateChangedCancellationMonths(current, cancellationStarts);
        }
        for (final month in months.where(current.overlaps)) {
          current.overridesByMonth[_periodKey(month)] = _overridesInMonth(
            event,
            month,
          );
        }
      }
      for (final month in months) {
        final key = _periodKey(month);
        final updated = {
          for (final event in singleEvents)
            if (_overlapsMonth(
              event,
              month,
              event.startDateTime,
              event.endDateTime,
            ))
              event.id: _encodeEvent(event),
        };
        // 後着の取得結果でも、保存した予定以外の変更は反映する。
        final previous = rows[key]?['data'];
        if (previous is List) {
          final previousEvents = _eventRows(previous);
          for (final entry in commits.entries) {
            if (entry.value <= timestamp) continue;
            final event = previousEvents[entry.key];
            if (event == null) {
              updated.remove(entry.key);
            } else {
              updated[entry.key] = event;
            }
          }
        }
        rows[key] = {'observedAt': timestamp, 'data': updated.values.toList()};
      }
      final keys = rows.keys.toList()
        ..sort((a, b) => _observedAt(rows[b]).compareTo(_observedAt(rows[a])));
      final retained = {
        for (final key in keys.take(_maxCachedMonths)) key: rows[key],
      };
      data['singleEvents'] = retained;
      _saveSeriesRows(data, series, retained.keys.toSet());
      final oldestObservation = _observedAt(retained.values.last);
      commits.removeWhere((_, committedAt) => committedAt <= oldestObservation);
      data['commits'] = commits;
      return true;
    });
    return !retryInitialFetch;
  }

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
        data.remove('events');
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

class _CachedSeries {
  _CachedSeries(this.parent, this.end, this.observedAt, this.overridesByMonth);

  final CalendarEventDto parent;
  final DateTime? end;
  final int observedAt;
  // キーなしは未取得、nullは親予定なし、空リストは取得済みで取消なし。
  final Map<String, List<CalendarEventOverride>?> overridesByMonth;

  bool overlaps(CalendarEventPeriod month) =>
      SharedCalendarCache._overlapsMonth(
        parent,
        month,
        parent.startDateTime,
        end,
      );
}
