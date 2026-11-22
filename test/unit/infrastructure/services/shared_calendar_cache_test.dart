import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';

void main() {
  final quarter = CalendarEventPeriod(
    from: DateTime(2026, 10),
    to: DateTime(2027),
  );
  final display = CalendarEventPeriod(
    from: DateTime(2026, 9, 25),
    to: DateTime(2027, 1, 7),
  );
  late SharedCalendarCache app;
  late SharedCalendarCache widget;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    app = SharedCalendarCache(directory: () async => directory);
    widget = SharedCalendarCache(directory: () async => directory);
  });

  test('予定が0件の購読期間も別の処理から利用し、前後の不足期間を特定する', () async {
    await app.saveEvents('account', 'group', quarter, []);
    final cached = await widget.loadEvents('account', 'group', display);
    expect(cached.slices.single.events, isEmpty);
    expect(cached.missing, [
      CalendarEventPeriod(from: display.from, to: quarter.from),
      CalendarEventPeriod(from: quarter.to, to: display.to),
    ]);
    expect((await widget.loadEvents('other', 'group', display)).missing, [
      display,
    ]);
    expect((await widget.loadEvents('account', 'other', display)).missing, [
      display,
    ]);
  });

  test('ウィジェットで取得した繰り返し予定と取消をアプリで読み直せる', () async {
    final series = CalendarEventDto(
      id: 'series',
      groupId: 'group',
      title: '予定',
      startDateTime: DateTime.utc(2026, 9, 28),
      endDateTime: DateTime.utc(2026, 9, 29),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY',
      version: 3,
      overrides: [
        CalendarEventOverride(originalStartDateTime: DateTime.utc(2026, 11, 2)),
      ],
    );
    await widget.saveEvents('account', 'group', display, [series]);
    final cached = await app.loadEvents('account', 'group', quarter);
    expect(cached.slices.single.events, [series]);
    expect(cached.missing, isEmpty);
  });

  test('空の再取得結果で上書きした期間の予定を破棄し、期間外は維持する', () async {
    final event = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      title: '予定',
      startDateTime: DateTime(2026, 10, 12, 10),
      endDateTime: DateTime(2026, 10, 12, 12),
      isAllDay: false,
    );
    await app.saveEvents('account', 'group', display, [event]);
    await widget.saveEvents('account', 'group', quarter, []);
    final cached = await app.loadEvents('account', 'group', quarter);
    expect(cached.slices.single.events, isEmpty);
    expect(cached.missing, isEmpty);
    expect(
      (await app.loadEvents('account', 'group', display)).missing,
      isEmpty,
    );
  });
}
