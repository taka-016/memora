import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';
import 'package:memora/infrastructure/services/shared_calendar_widget_data.dart';

void main() {
  test('通常表示は不足月だけ取得し、手動更新は連続する月と色ラベルをまとめて取得する', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final appCache = SharedCalendarCache(directory: () async => directory);
    final widgetCache = SharedCalendarCache(directory: () async => directory);
    final quarter = CalendarEventPeriod(
      from: DateTime(2026, 10),
      to: DateTime(2027),
    );
    final previous = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 9));
    final october = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 10));
    final november = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
    final periods = [previous, october, november];
    await appCache.saveEvents('online:a', 'g', quarter, []);
    await appCache.saveLabels('online:a', 'g', const [], observedAt: 1);
    final requests = <CalendarEventPeriod>[];
    var labelsRead = 0;
    final loader = SharedCalendarWidgetData(
      cache: widgetCache,
      currentOwnerId: () => 'online:a',
      fetchEvents: (groupId, {period}) async {
        expect(groupId, 'g');
        requests.add(period!);
        return [];
      },
      fetchLabels: (groupId) async {
        labelsRead++;
        return [
          const CalendarLabelDto(
            id: 'label',
            groupId: 'g',
            name: '予定',
            color: '#000000',
          ),
        ];
      },
    );

    final data = await loader.load('online:a', 'g', periods, force: false);
    expect(data.labels, isEmpty);
    expect(data.synchronizedPeriods, {previous});
    expect(data.sourceFiles.entries.single.value, greaterThan(0));
    expect(data.observedAt.keys, periods);
    expect(data.eventsByPeriod.keys, periods);
    expect(requests, [previous]);
    expect(labelsRead, 0);
    expect(await appCache.loadEvents('online:a', 'g', previous), isEmpty);

    requests.clear();
    final cached = await loader.load('online:a', 'g', periods, force: false);
    expect(requests, isEmpty);
    expect(cached.synchronizedPeriods, isEmpty);
    expect(cached.observedAt, data.observedAt);

    await loader.load(
      'online:a',
      'g',
      periods,
      force: false,
      forceLabels: true,
    );
    expect(requests, isEmpty);
    expect(labelsRead, 1);

    await loader.load('online:a', 'g', periods, force: true);
    expect(requests, [
      CalendarEventPeriod(from: previous.from, to: november.to),
    ]);
    expect(labelsRead, 2);
    expect((await appCache.loadLabels('online:a', 'g'))?.single.id, 'label');
  });

  test('不足月で系列を見つけたときは、表示対象の月で未取得の取消も取得する', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final appCache = SharedCalendarCache(directory: () async => directory);
    final october = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 10));
    final december = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 12));
    final series = CalendarEventDto(
      id: 'series',
      groupId: 'g',
      title: '毎週の予定',
      startDateTime: DateTime.utc(2026, 10, 2),
      endDateTime: DateTime.utc(2026, 10, 3),
      isAllDay: true,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR',
      version: 1,
    );
    final decemberSeries = series.copyWith(
      overrides: [
        CalendarEventOverride(originalStartDateTime: DateTime.utc(2026, 12, 4)),
      ],
    );
    await appCache.saveEvents('online:a', 'g', december, []);
    final requests = <CalendarEventPeriod>[];
    final loader = SharedCalendarWidgetData(
      cache: SharedCalendarCache(directory: () async => directory),
      currentOwnerId: () => 'online:a',
      fetchEvents: (_, {period}) async {
        requests.add(period!);
        return [period == december ? decemberSeries : series];
      },
      fetchLabels: (_) async => [],
    );

    final data = await loader.load('online:a', 'g', [
      october,
      december,
    ], force: false);
    expect(requests, [october, december]);
    expect(data.eventsByPeriod, {
      october: [series],
      december: [decemberSeries],
    });
    expect(data.synchronizedPeriods, {october, december});
  });

  test('手動取得の途中で保存した予定は古い応答で描画し直さない', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final appCache = SharedCalendarCache(directory: () async => directory);
    final month = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
    final original = CalendarEventDto(
      id: 'event',
      groupId: 'g',
      title: '編集前',
      version: 1,
      startDateTime: DateTime(2026, 11, 1, 9),
      endDateTime: DateTime(2026, 11, 1, 10),
      isAllDay: false,
    );
    final edited = original.copyWith(title: '編集後', version: 2);
    await appCache.saveEvents('online:a', 'g', month, [
      original,
    ], observedAt: 1);
    final loader = SharedCalendarWidgetData(
      cache: SharedCalendarCache(directory: () async => directory),
      currentOwnerId: () => 'online:a',
      fetchEvents: (_, {period}) async {
        await appCache.applyEventChanges('online:a', [
          (
            groupId: 'g',
            eventId: edited.id,
            event: edited,
            recurrenceEnd: null,
            version: edited.version,
          ),
        ], committedAt: 1 << 60);
        return [original];
      },
      fetchLabels: (_) async => [],
    );
    final data = await loader.load('online:a', 'g', [month], force: true);
    expect(data.eventsByPeriod[month], [edited]);
  });
}
