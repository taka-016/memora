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
      fetchEvents: (groupId, {required period}) async {
        expect(groupId, 'g');
        requests.add(period);
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

  test('不足月で系列を見つけたときは親予定の取消を取得済みの月にも反映する', () async {
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
      fetchEvents: (_, {required period}) async {
        requests.add(period);
        return [decemberSeries];
      },
      fetchLabels: (_) async => [],
    );

    final data = await loader.load('online:a', 'g', [
      october,
      december,
    ], force: false);
    expect(requests, [october]);
    expect(data.eventsByPeriod, {
      october: [decemberSeries],
      december: [decemberSeries],
    });
    expect(data.synchronizedPeriods, {october});
  });

  test('後で取得した月で繰り返し条件が変わったら、先に取得した月にも新しい親予定を反映する', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final cache = SharedCalendarCache(directory: () async => directory);
    final october = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 10));
    final november = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
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
    final updated = series.copyWith(recurrenceRule: 'FREQ=DAILY', version: 2);
    await cache.saveEvents('online:a', 'g', november, []);
    final requests = <CalendarEventPeriod>[];
    final loader = SharedCalendarWidgetData(
      cache: cache,
      currentOwnerId: () => 'online:a',
      fetchEvents: (_, {required period}) async {
        requests.add(period);
        return [requests.length == 1 ? series : updated];
      },
      fetchLabels: (_) async => [],
    );

    final data = await loader.load('online:a', 'g', [
      october,
      november,
      december,
    ], force: false);
    expect(requests, [october, december]);
    expect(data.eventsByPeriod.values, everyElement([updated]));
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
      fetchEvents: (_, {required period}) async {
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
