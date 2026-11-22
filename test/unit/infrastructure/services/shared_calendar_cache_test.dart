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
  late SharedCalendarCache app;
  late SharedCalendarCache widget;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('calendar-cache-');
    addTearDown(() => directory.delete(recursive: true));
    app = SharedCalendarCache(directory: () async => directory);
    widget = SharedCalendarCache(directory: () async => directory);
  });

  test('空の四半期も取得済みとして共有し、アカウント・グループ・期間を区別する', () async {
    await app.saveEvents('account', 'group', quarter, []);
    expect(await widget.loadEvents('account', 'group', quarter), isEmpty);
    expect(await widget.loadEvents('other', 'group', quarter), isNull);
    expect(await widget.loadEvents('account', 'other', quarter), isNull);
    final previous = CalendarEventPeriod.forQuarter(DateTime(2026, 9));
    expect(await widget.loadEvents('account', 'group', previous), isNull);
  });

  test('四半期の予定を月別に共有し、月またぎの予定と空の月も取り出せる', () async {
    final october = CalendarEventPeriod(
      from: DateTime(2026, 10),
      to: DateTime(2026, 11),
    );
    final november = CalendarEventPeriod(
      from: october.to,
      to: DateTime(2026, 12),
    );
    final december = CalendarEventPeriod(from: november.to, to: quarter.to);
    final trip = CalendarEventDto(
      id: 'trip',
      groupId: 'group',
      title: '月をまたぐ旅行',
      startDateTime: DateTime.utc(2026, 10, 31),
      endDateTime: DateTime.utc(2026, 11, 2),
      isAllDay: true,
    );
    final series = trip.copyWith(
      id: 'series',
      recurrenceRule: 'FREQ=DAILY;COUNT=2',
      startDateTime: DateTime.utc(2026, 10, 31),
      endDateTime: DateTime.utc(2026, 11, 1),
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: DateTime.utc(2026, 10, 31),
        ),
        CalendarEventOverride(originalStartDateTime: DateTime.utc(2026, 11, 1)),
      ],
    );

    await app.saveEvents('account', 'group', quarter, [trip, series]);

    final shared = await widget.loadGroup('account', 'group', [
      october,
      november,
      december,
    ]);
    expect(shared.eventsByPeriod, {
      october: [
        trip,
        series.copyWith(overrides: [series.overrides.first]),
      ],
      november: [
        trip,
        series.copyWith(overrides: [series.overrides.last]),
      ],
      december: isEmpty,
    });
    expect(shared.observedAt.keys, [october, november, december]);
    expect(
      await app.loadEvents('account', 'group', quarter),
      unorderedEquals([trip, series]),
    );
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
    await widget.saveEvents('account', 'group', quarter, [series]);
    final cached = await app.loadEvents('account', 'group', quarter);
    expect(cached, [series]);
  });

  test('月によって系列の版が異なる場合は取消が欠けた四半期を返さない', () async {
    final decemberCancellation = CalendarEventOverride(
      originalStartDateTime: DateTime.utc(2026, 12, 4),
    );
    final series = CalendarEventDto(
      id: 'series',
      groupId: 'group',
      title: '変更前',
      startDateTime: DateTime.utc(2026, 10, 2),
      endDateTime: DateTime.utc(2026, 10, 3),
      isAllDay: true,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR',
      version: 1,
      overrides: [decemberCancellation],
    );
    final november = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
    final december = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 12));
    final renamed = series.copyWith(title: '変更後', version: 2, overrides: []);
    await app.saveEvents('account', 'group', quarter, [series], observedAt: 1);
    await widget.saveEvents('account', 'group', november, [
      renamed,
    ], observedAt: 2);

    final shared = await widget.loadGroup('account', 'group', [
      november,
      december,
    ]);
    expect(shared.eventsByPeriod[november], [renamed]);
    expect(shared.eventsByPeriod[december], [series]);
    expect(await app.loadEvents('account', 'group', quarter), isNull);
  });

  test('更新済みの空の月に、別の月だけに残っている予定を表示しない', () async {
    final october = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 10));
    final november = CalendarEventPeriod.forCalendarMonth(DateTime(2026, 11));
    final event = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      title: '月をまたぐ予定',
      startDateTime: DateTime.utc(2026, 10, 31),
      endDateTime: DateTime.utc(2026, 11, 2),
      isAllDay: true,
      version: 1,
    );
    await app.saveEvents('account', 'group', quarter, [event], observedAt: 1);
    await widget.saveEvents('account', 'group', october, [], observedAt: 2);

    final shared = await widget.loadGroup('account', 'group', [
      october,
      november,
    ]);
    expect(shared.eventsByPeriod[october], isEmpty);
    expect(shared.eventsByPeriod[november], [event]);
    expect(await app.loadEvents('account', 'group', quarter), isNull);
  });

  test('最新の空結果で四半期を上書きし、遅れて届いた古い結果を破棄する', () async {
    final event = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      title: '予定',
      startDateTime: DateTime(2026, 10, 12, 10),
      endDateTime: DateTime(2026, 10, 12, 12),
      isAllDay: false,
    );
    await app.saveEvents('account', 'group', quarter, [event], observedAt: 1);
    await widget.saveEvents('account', 'group', quarter, [], observedAt: 3);
    await app.saveEvents('account', 'group', quarter, [event], observedAt: 2);
    expect(await app.loadEvents('account', 'group', quarter), isEmpty);
  });

  test('保存結果を該当する取得済み四半期だけに反映する', () async {
    final previous = CalendarEventPeriod.forQuarter(DateTime(2026, 9));
    final unrelated = CalendarEventPeriod.forQuarter(DateTime(2026, 5));
    final initial = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      title: '移動前',
      version: 1,
      startDateTime: DateTime(2026, 9, 20, 9),
      endDateTime: DateTime(2026, 9, 20, 10),
      isAllDay: false,
    );
    final moved = initial.copyWith(
      title: '移動後',
      version: 2,
      startDateTime: DateTime(2026, 11, 20, 9),
      endDateTime: DateTime(2026, 11, 20, 10),
    );
    await app.saveEvents('account', 'group', previous, [
      initial,
    ], observedAt: 1);
    await app.saveEvents('account', 'group', quarter, [], observedAt: 1);
    await app.saveEvents('account', 'group', unrelated, [], observedAt: 1);
    await app.applyEventChanges('account', [
      (
        groupId: 'group',
        eventId: 'event',
        event: moved,
        recurrenceEnd: null,
        version: 2,
      ),
    ], committedAt: 3);
    await widget.saveEvents('account', 'group', quarter, [], observedAt: 2);
    expect(await widget.loadEvents('account', 'group', quarter), [moved]);
    expect(await widget.loadEvents('account', 'group', previous), isEmpty);
    expect(await widget.loadEvents('account', 'group', unrelated), isEmpty);
    expect(
      await widget.loadEvents(
        'account',
        'group',
        CalendarEventPeriod.forQuarter(DateTime(2027, 2)),
      ),
      isNull,
    );
  });

  test('保存前に始まった取得でも、同じ四半期のほかの予定は反映する', () async {
    final original = CalendarEventDto(
      id: 'local',
      groupId: 'group',
      title: '編集前',
      version: 1,
      startDateTime: DateTime(2026, 11, 1, 9),
      endDateTime: DateTime(2026, 11, 1, 10),
      isAllDay: false,
    );
    final edited = original.copyWith(title: '編集後', version: 2);
    final remote = original.copyWith(id: 'remote', title: '別端末で追加');
    await app.saveEvents('account', 'group', quarter, [
      original,
    ], observedAt: 1);
    await app.applyEventChanges('account', [
      (
        groupId: 'group',
        eventId: original.id,
        event: edited,
        recurrenceEnd: null,
        version: edited.version,
      ),
    ], committedAt: 3);
    await widget.saveEvents('account', 'group', quarter, [
      original,
      remote,
    ], observedAt: 2);
    expect(
      await app.loadEvents('account', 'group', quarter),
      unorderedEquals([edited, remote]),
    );
  });

  test('初回取得と保存が重なったときは変更前の応答を取得済みにしない', () async {
    final created = CalendarEventDto(
      id: 'new',
      groupId: 'group',
      title: '新しい予定',
      version: 1,
      startDateTime: DateTime(2026, 11, 1, 9),
      endDateTime: DateTime(2026, 11, 1, 10),
      isAllDay: false,
    );
    await app.applyEventChanges('account', [
      (
        groupId: 'group',
        eventId: created.id,
        event: created,
        recurrenceEnd: null,
        version: created.version,
      ),
    ], committedAt: 3);
    final accepted = await widget.saveEvents(
      'account',
      'group',
      quarter,
      [],
      observedAt: 2,
    );
    expect(accepted, isFalse);
    expect(await app.loadEvents('account', 'group', quarter), isNull);
    await widget.saveEvents('account', 'group', quarter, [
      created,
    ], observedAt: 4);
    expect(await app.loadEvents('account', 'group', quarter), [created]);
  });

  test('キャッシュにまだ載っていない削除済みの系列も後着の取得結果から除く', () async {
    final series = CalendarEventDto(
      id: 'series',
      groupId: 'group',
      title: '削除した系列',
      version: 1,
      startDateTime: DateTime.utc(2026, 1, 3),
      endDateTime: DateTime.utc(2026, 1, 4),
      isAllDay: true,
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=SA',
    );
    final unrelated = series.copyWith(id: 'other', title: '別の系列');
    await widget.saveEvents('account', 'group', quarter, [], observedAt: 1);
    await app.applyEventChanges('account', [
      (
        groupId: 'group',
        eventId: series.id,
        event: null,
        recurrenceEnd: null,
        version: series.version,
      ),
    ], committedAt: 3);
    await widget.saveEvents('account', 'group', quarter, [
      series,
      unrelated,
    ], observedAt: 2);
    expect(await app.loadEvents('account', 'group', quarter), [unrelated]);
  });
}
