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
  for (final cancelled in [false, true]) {
    test('月末補正後の対応回へ個別変更と取消しのキーを追従させる（$cancelled）', () async {
      final february = DateTime.utc(2026, 2, 28);
      final original = source.copyWith(
        startDateTime: DateTime.utc(2026, 1, 31),
        endDateTime: DateTime.utc(2026, 1, 31),
        recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=3',
        overrides: [
          CalendarEventOverride(
            originalStartDateTime: february,
            isCancelled: cancelled,
            title: cancelled ? null : '個別変更',
            labelId: cancelled ? null : 'label',
            isAllDay: cancelled ? null : true,
            startDateTime: cancelled ? null : february,
            endDateTime: cancelled ? null : february,
          ),
        ],
      );
      await usecase.execute(
        original,
        original.startDateTime,
        CalendarChangeScope.all,
        changes: original.copyWith(
          startDateTime: DateTime.utc(2026, 1, 30),
          endDateTime: DateTime.utc(2026, 1, 30),
          recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=30;COUNT=3',
        ),
      );
      final saved =
          verify(repository.replaceCalendarEvent(any, captureAny, null))
                  .captured
                  .single
              as CalendarEvent;
      expect(saved.overrides.single.originalStartDateTime, february);
      final values = expander.expand(
        CalendarEventMapper.toDto(saved),
        DateTime.utc(2026, 2),
        DateTime.utc(2026, 3),
      );
      expect(values, hasLength(cancelled ? 0 : 1));
      if (!cancelled) expect(values.single.title, '個別変更');
    });
  }
  for (final explicit in [false, true]) {
    test('月末補正回からの分割でも元の31日基準と残り回数を維持する（$explicit）', () async {
      final original = source.copyWith(
        startDateTime: DateTime.utc(2026, 1, 31),
        endDateTime: DateTime.utc(2026, 1, 31),
        recurrenceRule:
            'FREQ=MONTHLY;${explicit ? 'BYMONTHDAY=31;' : ''}COUNT=4',
        overrides: [],
      );
      final day = DateTime.utc(2026, 2, 28);
      await usecase.execute(
        original,
        day,
        CalendarChangeScope.following,
        changes: original.copyWith(
          title: '変更',
          startDateTime: day,
          endDateTime: day,
        ),
      );
      final saved = verify(
        repository.replaceCalendarEvent(any, captureAny, captureAny),
      ).captured;
      final next = saved.last as CalendarEvent;
      expect(next.recurrenceRule, contains('BYMONTHDAY=31'));
      expect(next.recurrenceRule, contains('COUNT=3'));
      expect(
        expander
            .expand(
              CalendarEventMapper.toDto(next),
              DateTime.utc(2026, 2),
              DateTime.utc(2026, 6),
            )
            .map((v) => v.startDateTime),
        [day, DateTime.utc(2026, 3, 31), DateTime.utc(2026, 4, 30)],
      );
    });
  }
  test('曜日を自動追従した回を分割しても元の回数を超えない', () async {
    final original = source.copyWith(
      startDateTime: DateTime.utc(2026, 10, 1),
      endDateTime: DateTime.utc(2026, 10, 1),
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=5',
      overrides: [],
    );
    await usecase.execute(
      original,
      DateTime.utc(2026, 10, 15),
      CalendarChangeScope.following,
      changes: original.copyWith(
        startDateTime: DateTime.utc(2026, 10, 16),
        endDateTime: DateTime.utc(2026, 10, 16),
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=FR;COUNT=5',
      ),
    );
    final next =
        verify(repository.replaceCalendarEvent(any, any, captureAny))
                .captured
                .single
            as CalendarEvent;
    expect(next.recurrenceRule, 'FREQ=WEEKLY;BYDAY=FR;COUNT=3');
  });
  for (final scope in [
    CalendarChangeScope.all,
    CalendarChangeScope.following,
  ]) {
    for (final deleting in [false, true]) {
      test('個別変更済みの回から系列の変更と削除を拒否する（$scope・$deleting）', () async {
        await expectLater(
          usecase.execute(
            source,
            DateTime.utc(2026, 10, 4),
            scope,
            changes: deleting ? null : source.copyWith(title: '再編集'),
          ),
          throwsA(isA<ApplicationValidationException>()),
        );
        verifyZeroInteractions(repository);
      });
    }
  }
  test('個別変更のリセットは対象の上書きだけを外して元の系列へ戻す', () async {
    await usecase.resetOverride(source, DateTime.utc(2026, 10, 4));
    final saved = verify(
      repository.replaceCalendarEvent(captureAny, captureAny, null),
    ).captured;
    expect(saved.first, CalendarEventMapper.toEntity(source));
    final result = saved.last as CalendarEvent;
    expect(result.overrides, [source.overrides.first]);
    expect(result.recurrenceRule, source.recurrenceRule);
    expect(result.startDateTime, source.startDateTime);
    final restored = expander
        .expand(
          CalendarEventMapper.toDto(result),
          DateTime.utc(2026, 10, 4),
          DateTime.utc(2026, 10, 5),
        )
        .singleWhere(
          (value) => value.originalStartDateTime == DateTime.utc(2026, 10, 4),
        );
    expect(restored.title, source.title);
    expect(restored.labelId, source.labelId);
    expect(restored.startDateTime, DateTime.utc(2026, 10, 4));
    expect(restored.endDateTime, DateTime.utc(2026, 10, 6));
    expect(restored.isAllDay, source.isAllDay);
    await usecase.execute(
      CalendarEventMapper.toDto(result),
      DateTime.utc(2026, 10, 4),
      CalendarChangeScope.all,
      changes: CalendarEventMapper.toDto(result).copyWith(
        startDateTime: DateTime.utc(2026, 10, 4),
        endDateTime: DateTime.utc(2026, 10, 6),
      ),
    );
    verify(repository.replaceCalendarEvent(any, any, null)).called(1);
  });
  test('個別変更のない回はリセットせず保存を拒否する', () async {
    await expectLater(
      usecase.resetOverride(source, DateTime.utc(2026, 10, 3)),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyZeroInteractions(repository);
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
  test('これ以降の分割は対象範囲の個別変更も引き継いで残り回数を保つ', () async {
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
    expect(after.overrides, [source.overrides.last]);
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
  test('すべての変更は個別の内容を維持して系列の初回へ日時差分を適用する', () async {
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
    expect(saved.overrides.map((value) => value.originalStartDateTime), [
      DateTime.utc(2026, 10, 3),
      DateTime.utc(2026, 10, 5),
    ]);
    expect(
      saved.overrides.last.startDateTime,
      source.overrides.last.startDateTime,
    );
    expect(saved.overrides.last.title, source.overrides.last.title);
  });
  for (final scope in [
    CalendarChangeScope.all,
    CalendarChangeScope.following,
  ]) {
    test('繰り返し条件と終了回数を変えても個別変更を維持する（$scope）', () async {
      await usecase.execute(
        source,
        DateTime.utc(2026, 10, 3),
        scope,
        changes: source.copyWith(
          startDateTime: DateTime.utc(2026, 10, 3),
          endDateTime: DateTime.utc(2026, 10, 5),
          recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=3;COUNT=1',
        ),
      );
      final saved = verify(
        repository.replaceCalendarEvent(any, captureAny, captureAny),
      ).captured;
      final result =
          (scope == CalendarChangeScope.all ? saved[0] : saved[1])
              as CalendarEvent;
      expect(result.overrides.last, source.overrides.last);
      final occurrences = expander.expand(
        CalendarEventMapper.toDto(result),
        DateTime.utc(2026, 10),
        DateTime.utc(2026, 12),
      );
      expect(
        occurrences.singleWhere((value) => value.title == '移動').startDateTime,
        DateTime.utc(2026, 11, 1),
      );
      final savedSeries = CalendarEventMapper.toDto(result)
          .copyWith(id: '保存済み');
      await usecase.execute(
        savedSeries,
        result.overrides.last.originalStartDateTime,
        CalendarChangeScope.only,
        changes: savedSeries.copyWith(
          title: '個別の再編集',
          startDateTime: result.overrides.last.startDateTime,
          endDateTime: result.overrides.last.endDateTime,
        ),
      );
      final edited =
          verify(repository.replaceCalendarEvent(any, captureAny, null))
                  .captured
                  .single
              as CalendarEvent;
      expect(edited.overrides.last.title, '個別の再編集');
    });
  }
  for (final scope in [
    CalendarChangeScope.all,
    CalendarChangeScope.following,
  ]) {
    for (final pattern in [
      (
        rule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=5',
        selected: DateTime.utc(2026, 10, 8),
        moved: DateTime.utc(2026, 10, 9),
        expected: 'BYDAY=FR',
      ),
      (
        rule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,TH;COUNT=5',
        selected: DateTime.utc(2026, 10, 15),
        moved: DateTime.utc(2026, 10, 16),
        expected: 'BYDAY=TU,FR',
      ),
      (
        rule: 'FREQ=MONTHLY;BYMONTHDAY=1;COUNT=5',
        selected: DateTime.utc(2026, 11, 1),
        moved: DateTime.utc(2026, 11, 2),
        expected: 'BYMONTHDAY=2',
      ),
      (
        rule: 'FREQ=MONTHLY;BYDAY=1TH;COUNT=5',
        selected: DateTime.utc(2026, 11, 5),
        moved: DateTime.utc(2026, 11, 12),
        expected: 'BYDAY=2TH',
      ),
    ]) {
      test('日付移動に系列の曜日・日付条件を追従し終了回数を保つ（${pattern.rule}・$scope）', () async {
        final series = source.copyWith(
          recurrenceRule: pattern.rule,
          overrides: [],
        );
        await usecase.execute(
          series,
          pattern.selected,
          scope,
          changes: series.copyWith(
            startDateTime: pattern.moved,
            endDateTime: pattern.moved.add(const Duration(days: 2)),
          ),
        );
        final saved = verify(
          repository.replaceCalendarEvent(any, captureAny, captureAny),
        ).captured;
        final result = CalendarEventMapper.toDto(
          (scope == CalendarChangeScope.all ? saved[0] : saved[1])
              as CalendarEvent,
        );
        expect(result.recurrenceRule, contains(pattern.expected));
        final start = scope == CalendarChangeScope.all
            ? series.startDateTime.add(
                pattern.moved.difference(pattern.selected),
              )
            : pattern.moved;
        expect(result.startDateTime, start);
        final occurrences = expander.expand(
          result,
          DateTime.utc(2026),
          DateTime.utc(2030),
        );
        expect(occurrences.first.startDateTime, start);
        final before = scope == CalendarChangeScope.all
            ? 0
            : expander
                  .expand(series, series.startDateTime, pattern.selected)
                  .length;
        expect(occurrences, hasLength(5 - before));
      });
    }
  }
  for (final allDay in [true, false]) {
    for (final scope in [
      CalendarChangeScope.all,
      CalendarChangeScope.following,
    ]) {
      test('日付移動と終日区分変更でも曜日と終了日を維持する（$allDay・$scope）', () async {
        final series = source.copyWith(
          startDateTime: DateTime.utc(2026, 10, 2, allDay ? 0 : 9),
          endDateTime: DateTime.utc(2026, 10, 5, allDay ? 0 : 9),
          isAllDay: allDay,
          timeZone: allDay ? null : 'Asia/Tokyo',
          recurrenceRule: allDay
              ? 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101'
              : 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101T145959Z',
          overrides: [],
        );
        await usecase.execute(
          series,
          series.startDateTime,
          scope,
          changes: series.copyWith(
            startDateTime: DateTime.utc(2026, 10, 3, allDay ? 9 : 0),
            endDateTime: DateTime.utc(2026, 10, 6, allDay ? 9 : 0),
            isAllDay: !allDay,
            timeZone: allDay ? 'Asia/Tokyo' : null,
            recurrenceRule: allDay
                ? 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101T145959Z'
                : 'FREQ=WEEKLY;BYDAY=FR;UNTIL=20270101',
          ),
        );
        final result =
            verify(repository.replaceCalendarEvent(any, captureAny, null))
                    .captured
                    .single
                as CalendarEvent;
        expect(result.recurrenceRule, contains('BYDAY=SA'));
        expect(
          result.recurrenceRule,
          endsWith(allDay ? 'UNTIL=20270101T145959Z' : 'UNTIL=20270101'),
        );
        expect(
          expander.expand(
            CalendarEventMapper.toDto(result),
            DateTime.utc(2026, 10),
            DateTime.utc(2027),
          ),
          isNotEmpty,
        );
      });
    }
  }
  for (final pattern in [
    (
      rule: 'FREQ=WEEKLY;BYDAY=FR;COUNT=4',
      expected: 'FREQ=WEEKLY;BYDAY=TH;COUNT=4',
    ),
    (
      rule: 'FREQ=WEEKLY;BYDAY=FR,SU;COUNT=4',
      expected: 'FREQ=WEEKLY;BYDAY=TH,SA;COUNT=4',
    ),
    (
      rule: 'FREQ=MONTHLY;BYMONTHDAY=2;COUNT=4',
      expected: 'FREQ=MONTHLY;BYMONTHDAY=1;COUNT=4',
    ),
    (
      rule: 'FREQ=MONTHLY;BYDAY=1FR;UNTIL=20270101',
      expected: 'FREQ=MONTHLY;BYDAY=1TH;UNTIL=20270101',
    ),
  ]) {
    test('後続回で明示変更した条件を全系列の保存初回へ整合する（${pattern.rule}）', () async {
      final series = source.copyWith(overrides: []);
      final selected = DateTime.utc(2026, 10, 2);
      await usecase.execute(
        series,
        selected,
        CalendarChangeScope.all,
        changes: series.copyWith(
          startDateTime: selected,
          endDateTime: selected.add(const Duration(days: 2)),
          recurrenceRule: pattern.rule,
        ),
      );
      final result =
          verify(repository.replaceCalendarEvent(any, captureAny, null))
                  .captured
                  .single
              as CalendarEvent;
      expect(result.startDateTime, series.startDateTime);
      expect(
        result.endDateTime.difference(result.startDateTime),
        const Duration(days: 2),
      );
      expect(result.recurrenceRule, pattern.expected);
      final occurrences = expander.expand(
        CalendarEventMapper.toDto(result),
        DateTime.utc(2026, 10),
        DateTime.utc(2027, 2),
      );
      expect(occurrences.first.startDateTime, series.startDateTime);
      if (pattern.rule.contains('COUNT=4')) expect(occurrences, hasLength(4));
    });
  }
  test('個別回の移動では元の系列の曜日を変更しない', () async {
    final series = source.copyWith(
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=TH;COUNT=5',
      overrides: [],
    );
    await usecase.execute(
      series,
      DateTime.utc(2026, 10, 8),
      CalendarChangeScope.only,
      changes: series.copyWith(
        startDateTime: DateTime.utc(2026, 10, 9),
        endDateTime: DateTime.utc(2026, 10, 10),
      ),
    );
    final result =
        verify(repository.replaceCalendarEvent(any, captureAny, null))
                .captured
                .single
            as CalendarEvent;
    expect(result.recurrenceRule, series.recurrenceRule);
    expect(result.overrides.single.startDateTime, DateTime.utc(2026, 10, 9));
  });
  test('これ以降の削除は移動先に関係なく元のキーで個別変更も削除する', () async {
    await usecase.execute(
      source,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.following,
    );
    final result =
        verify(repository.replaceCalendarEvent(any, captureAny, null))
                .captured
                .single
            as CalendarEvent;
    expect(result.overrides, [source.overrides.first]);
    expect(
      expander
          .expand(
            CalendarEventMapper.toDto(result),
            DateTime.utc(2026, 10),
            DateTime.utc(2026, 12),
          )
          .any((value) => value.title == '移動'),
      isFalse,
    );
  });
  test('系列の時刻変更は個別の実日時を維持し二重に表示しない', () async {
    final timed = source.copyWith(isAllDay: false, timeZone: 'Asia/Tokyo');
    await usecase.execute(
      timed,
      DateTime.utc(2026, 10, 3),
      CalendarChangeScope.all,
      changes: timed.copyWith(
        startDateTime: DateTime.utc(2026, 10, 3, 1),
        endDateTime: DateTime.utc(2026, 10, 5, 1),
      ),
    );
    final result =
        verify(repository.replaceCalendarEvent(any, captureAny, null))
                .captured
                .single
            as CalendarEvent;
    expect(
      result.overrides.last.startDateTime,
      source.overrides.last.startDateTime,
    );
    expect(
      result.overrides.last.originalStartDateTime,
      DateTime.utc(2026, 10, 4, 1),
    );
    final occurrences = expander.expand(
      CalendarEventMapper.toDto(result),
      DateTime.utc(2026, 10),
      DateTime.utc(2026, 12),
    );
    expect(occurrences, hasLength(4));
    expect(
      occurrences.where(
        (value) => value.originalStartDateTime == DateTime.utc(2026, 10, 4, 1),
      ),
      hasLength(1),
    );
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
  for (final cancelled in [false, true]) {
    test('繰り返し解除で個別変更または取消し済みの初回を再生成しない（$cancelled）', () async {
      final first = CalendarEventOverride(
        originalStartDateTime: source.startDateTime,
        isCancelled: cancelled,
        title: cancelled ? null : '初回個別',
        labelId: cancelled ? null : source.labelId,
        isAllDay: cancelled ? null : true,
        startDateTime: cancelled ? null : DateTime.utc(2026, 11, 10),
        endDateTime: cancelled ? null : DateTime.utc(2026, 11, 11),
      );
      final series = source.copyWith(overrides: [first, ...source.overrides]);
      await usecase.execute(
        series,
        DateTime.utc(2026, 10, 3),
        CalendarChangeScope.all,
        changes: CalendarEventDto(
          id: source.id,
          groupId: source.groupId,
          labelId: source.labelId,
          title: '単発',
          startDateTime: DateTime.utc(2026, 10, 3),
          endDateTime: DateTime.utc(2026, 10, 5),
          isAllDay: true,
        ),
      );
      final captured = verify(
        repository.replaceCalendarEvent(
          any,
          captureAny,
          null,
          preservedEvents: captureAnyNamed('preservedEvents'),
        ),
      ).captured;
      expect(captured.first, isNull);
      final individuals = captured.last as List<CalendarEvent>;
      expect(
        individuals.map((value) => value.title),
        cancelled ? ['移動'] : ['初回個別', '移動'],
      );
    });
  }
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
    final captured = verify(
      repository.replaceCalendarEvent(
        any,
        captureAny,
        null,
        preservedEvents: captureAnyNamed('preservedEvents'),
      ),
    ).captured;
    final saved = captured.first as CalendarEvent;
    expect(saved.recurrenceRule, isNull);
    expect(saved.timeZone, isNull);
    expect(saved.startDateTime, DateTime.utc(2026, 10, 1, 9));
    final retained = captured.last as List<CalendarEvent>;
    expect(retained.single.startDateTime, source.overrides.last.startDateTime);
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
