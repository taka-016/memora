import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';
import 'package:memora/infrastructure/services/shared_calendar_widget_data.dart';

void main() {
  test('通常表示は不足期間だけ取得し、手動更新は期間全体と色ラベルを取得する', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final appCache = SharedCalendarCache(directory: () async => directory);
    final widgetCache = SharedCalendarCache(directory: () async => directory);
    final quarter = CalendarEventPeriod(
      from: DateTime(2026, 10),
      to: DateTime(2027),
    );
    final previous = CalendarEventPeriod.forQuarter(DateTime(2026, 9));
    final periods = [previous, quarter];
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
    expect(requests, periods);
    expect(labelsRead, 2);
    expect((await appCache.loadLabels('online:a', 'g'))?.single.id, 'label');
  });

  test('手動取得の途中で保存した予定は古い応答で描画し直さない', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final appCache = SharedCalendarCache(directory: () async => directory);
    final quarter = CalendarEventPeriod.forQuarter(DateTime(2026, 11));
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
    await appCache.saveEvents('online:a', 'g', quarter, [
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
    final data = await loader.load('online:a', 'g', [quarter], force: true);
    expect(data.eventsByPeriod[quarter], [edited]);
  });
}
