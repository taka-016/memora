import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    expect(data.synchronized, isTrue);
    expect(data.sourceFiles.entries.single.value, greaterThan(0));
    expect(data.observedAt.keys, periods);
    expect(data.eventsByPeriod.keys, periods);
    expect(requests, [previous]);
    expect(labelsRead, 0);
    expect(await appCache.loadEvents('online:a', 'g', previous), isEmpty);

    requests.clear();
    final cached = await loader.load('online:a', 'g', periods, force: false);
    expect(requests, isEmpty);
    expect(cached.synchronized, isFalse);
    expect(cached.observedAt, data.observedAt);

    await loader.load('online:a', 'g', periods, force: true);
    expect(requests, periods);
    expect(labelsRead, 1);
    expect((await appCache.loadLabels('online:a', 'g'))?.single.id, 'label');
  });
}
