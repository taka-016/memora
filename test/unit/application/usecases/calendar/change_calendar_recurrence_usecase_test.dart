import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

import 'calendar_usecases_test.mocks.dart';

void main() {
  final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
  final source = CalendarEventDto(
    id: 'event',
    groupId: 'group',
    labelId: 'label',
    title: '旅行',
    startDateTime: DateTime.utc(2026, 10, 1),
    endDateTime: DateTime.utc(2026, 10, 3),
    isAllDay: true,
    recurrenceRule: 'FREQ=DAILY;COUNT=5',
    overrides: [
      CalendarEventOverride(
        originalStartDateTime: DateTime.utc(2026, 10, 2),
        isCancelled: true,
      ),
      CalendarEventOverride(
        originalStartDateTime: DateTime.utc(2026, 10, 4),
        isCancelled: false,
        title: '移動',
        labelId: 'label',
        isAllDay: true,
        startDateTime: DateTime.utc(2026, 11, 1),
        endDateTime: DateTime.utc(2026, 11, 2),
      ),
    ],
  );
  late MockCalendarEventRepository repository;
  late ChangeCalendarRecurrenceUsecase usecase;
  setUp(() {
    repository = MockCalendarEventRepository();
    usecase = ChangeCalendarRecurrenceUsecase(repository, expander);
  });
  test('個別回の移動は元のキーで保存し他の取消しと移動を維持する', () async {
    final changes = source.copyWith(
      startDateTime: DateTime.utc(2026, 12, 3),
      endDateTime: DateTime.utc(2026, 12, 4),
      title: '変更',
    );
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.only,
      changes: changes,
    );
    final saved = verify(repository.replaceCalendarEvent(any, captureAny, any))
        .captured
        .single;
    final result = expander.expand(
      CalendarEventMapper.toDto(saved as CalendarEvent),
      DateTime.utc(2026, 10),
      DateTime.utc(2027),
    );
    expect(
      result.where((v) => v.originalStartDateTime == DateTime.utc(2026, 10, 2)),
      isEmpty,
    );
    expect(
      result.singleWhere((v) => v.title == '変更').startDateTime,
      DateTime.utc(2026, 12, 3),
    );
    expect(result.where((v) => v.title == '移動'), hasLength(1));
  });
  test('これ以降の分割は過去の上書きを維持し対象範囲の上書きを解除して残り回数を保つ', () async {
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.following,
      changes: source.copyWith(
        startDateTime: DateTime.utc(2026, 10, 3),
        endDateTime: DateTime.utc(2026, 10, 5),
        title: '新系列',
      ),
    );
    final saved = verify(
      repository.replaceCalendarEvent(any, captureAny, captureAny),
    ).captured;
    final before = CalendarEventMapper.toDto(saved[0] as CalendarEvent);
    final after = CalendarEventMapper.toDto(saved[1] as CalendarEvent);
    expect(before.overrides, [source.overrides.first]);
    expect(after.overrides, isEmpty);
    expect(
      expander
          .expand(before, DateTime.utc(2026, 10), DateTime.utc(2026, 12))
          .map((v) => v.originalStartDateTime),
      [DateTime.utc(2026, 10, 1)],
    );
    expect(
      expander.expand(after, DateTime.utc(2026, 10), DateTime.utc(2026, 12)),
      hasLength(3),
    );
  });
  test('これ以降の削除は移動先でなく元の開始日時で範囲を選ぶ', () async {
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 4),
      CalendarChangeScope.following,
    );
    final saved = verify(repository.replaceCalendarEvent(any, captureAny, null))
        .captured
        .single;
    expect(saved.overrides, [source.overrides.first]);
    expect(
      expander
          .expand(
            CalendarEventMapper.toDto(saved as CalendarEvent),
            DateTime.utc(2026, 10),
            DateTime.utc(2026, 12),
          )
          .map((v) => v.originalStartDateTime),
      [DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 3)],
    );
  });
  test('すべての変更は選択した回の差分を初回へ適用し上書きを解除する', () async {
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.all,
      changes: source.copyWith(
        startDateTime: DateTime.utc(2026, 10, 4),
        endDateTime: DateTime.utc(2026, 10, 6),
        title: '変更',
      ),
    );
    final saved = verify(repository.replaceCalendarEvent(any, captureAny, null))
        .captured
        .single;
    expect(saved.startDateTime, DateTime.utc(2026, 10, 2));
    expect(saved.overrides, isEmpty);
  });
  test('初回からの削除と全系列の削除は親を削除する', () async {
    for (final scope in [
      CalendarChangeScope.following,
      CalendarChangeScope.all,
    ]) {
      await usecase.execute(source, source.startDateTime, scope);
    }
    verify(repository.replaceCalendarEvent(any, null, null)).called(2);
  });
  test('終日系列を時刻付き単発へ変更して繰り返しとタイムゾーンを解除する', () async {
    final changes = CalendarEventDto(
      id: source.id,
      groupId: source.groupId,
      labelId: source.labelId,
      title: '単発',
      startDateTime: DateTime.utc(2026, 10, 3, 9),
      endDateTime: DateTime.utc(2026, 10, 3, 10),
      isAllDay: false,
    );
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.all,
      changes: changes,
    );
    final saved =
        verify(repository.replaceCalendarEvent(any, captureAny, null))
                .captured
                .single
            as CalendarEvent;
    expect(saved.recurrenceRule, isNull);
    expect(saved.timeZone, isNull);
    expect(saved.startDateTime, DateTime.utc(2026, 10, 1, 9));
  });
  test('夏時間で欠落した回を除いて分割後の残り回数を決める', () async {
    final timed = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      labelId: 'label',
      title: '予定',
      startDateTime: DateTime.utc(2026, 3, 7, 7, 30),
      endDateTime: DateTime.utc(2026, 3, 7, 8, 30),
      isAllDay: false,
      recurrenceRule: 'FREQ=DAILY;COUNT=4',
      timeZone: 'America/New_York',
    );
    final original = DateTime.utc(2026, 3, 10, 6, 30);
    await usecase.execute(
      timed,
      original,
      CalendarChangeScope.following,
      changes: timed.copyWith(
        startDateTime: original,
        endDateTime: original.add(const Duration(hours: 1)),
      ),
    );
    final saved = verify(
      repository.replaceCalendarEvent(any, captureAny, captureAny),
    ).captured;
    expect(
      expander.expand(
        CalendarEventMapper.toDto(saved[0] as CalendarEvent),
        DateTime.utc(2026, 3, 7),
        DateTime.utc(2026, 3, 15),
      ),
      hasLength(2),
    );
    expect(
      expander.expand(
        CalendarEventMapper.toDto(saved[1] as CalendarEvent),
        DateTime.utc(2026, 3, 7),
        DateTime.utc(2026, 3, 15),
      ),
      hasLength(2),
    );
  });
  test('系列にない回と別グループの入力は保存前に拒否する', () async {
    for (final original in [
      DateTime.utc(2026, 9, 30),
      DateTime.utc(2026, 10, 6),
    ]) {
      await expectLater(
        usecase.execute(source, original, CalendarChangeScope.only),
        throwsA(isA<ApplicationValidationException>()),
      );
    }
    await expectLater(
      usecase.execute(
        source,
        source.startDateTime,
        CalendarChangeScope.all,
        changes: source.copyWith(groupId: 'other'),
      ),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyZeroInteractions(repository);
  });
}
