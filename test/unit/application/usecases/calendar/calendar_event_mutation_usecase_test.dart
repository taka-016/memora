import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/move_calendar_event_usecase.dart';

import 'package:memora/application/usecases/calendar/calendar_event_mutation_usecase.dart';

import 'calendar_event_mutation_usecase_test.mocks.dart';

@GenerateMocks([
  MoveCalendarEventUsecase,
  CreateCalendarEventUsecase,
  UpdateCalendarEventUsecase,
  DeleteCalendarEventUsecase,
  ChangeCalendarRecurrenceUsecase,
])
void main() {
  group('予定の保存・削除の判定', () {
    late MockCreateCalendarEventUsecase create;
    late MockUpdateCalendarEventUsecase update;
    late MockDeleteCalendarEventUsecase delete;
    late MockMoveCalendarEventUsecase move;
    late MockChangeCalendarRecurrenceUsecase change;
    late CalendarEventMutationUsecase usecase;
    const member = MemberDto(id: 'self', displayName: '本人');
    late CalendarEventDto series;
    late CalendarEventDto occurrence;
    setUp(() {
      create = MockCreateCalendarEventUsecase();
      update = MockUpdateCalendarEventUsecase();
      delete = MockDeleteCalendarEventUsecase();
      move = MockMoveCalendarEventUsecase();
      change = MockChangeCalendarRecurrenceUsecase();
      when(change.execute(any, any, any)).thenAnswer((_) async => null);
      usecase = CalendarEventMutationUsecase(
        create: () => create,
        update: () => update,
        deleteEvent: () => delete,
        move: () => move,
        changeRecurrence: () => change,
      );
      series = CalendarEventDto(
        id: 'event',
        version: 3,
        overridesFingerprint: '取消情報',
        groupId: 'a',
        labelType: 'group',
        title: '予定',
        startDateTime: DateTime.utc(2026, 11, 1),
        endDateTime: DateTime.utc(2026, 11, 2),
        isAllDay: true,
        recurrenceRule: 'FREQ=DAILY;COUNT=5',
      );
      occurrence = series.copyWith(
        startDateTime: DateTime.utc(2026, 11, 3),
        endDateTime: DateTime.utc(2026, 11, 4),
        originalStartDateTime: DateTime.utc(2026, 11, 3),
      );
    });

    test('新規作成の保存IDを返し既存予定は更新する', () async {
      final input = series.copyWith(id: '');
      when(create.execute(input)).thenAnswer((_) async => 'created');
      final created = await usecase.save(input, currentMember: () => member);
      expect(created.savedId, 'created');
      expect(created.affectedGroupIds, {'a'});
      final updated = await usecase.save(series, currentMember: () => member);
      expect(updated.savedId, 'event');
      expect(updated.affectedGroupIds, {'a'});
      verify(create.execute(input)).called(1);
      verify(update.execute(series)).called(1);
    });

    for (final scope in CalendarChangeScope.values) {
      test('繰り返し予定の保存は${scope.name}の範囲と編集開始時の系列を渡す', () async {
        final input = occurrence.copyWith(title: '変更');
        when(
          change.execute(
            series,
            occurrence.originalStartDateTime!,
            scope,
            changes: input,
          ),
        ).thenAnswer((_) async => 'saved');
        final result = await usecase.save(
          input,
          currentMember: () => member,
          expected: occurrence,
          expectedSeries: series,
          scope: scope,
        );
        expect(result.savedId, 'saved');
        expect(result.affectedGroupIds, {'a'});
        verify(
          change.execute(
            series,
            occurrence.originalStartDateTime!,
            scope,
            changes: input,
          ),
        ).called(1);
        verifyZeroInteractions(update);
      });
      test('繰り返し予定の削除は${scope.name}の範囲と編集開始時の系列を渡す', () async {
        final result = await usecase.delete(
          occurrence,
          expectedSeries: series,
          scope: scope,
        );
        expect(result.affectedGroupIds, {'a'});
        verify(change.execute(series, occurrence.originalStartDateTime!, scope))
            .called(1);
        verifyZeroInteractions(delete);
      });
    }

    test('繰り返し予定の移動は変更範囲より優先して系列を移動する', () async {
      final input = occurrence.copyWith(groupId: 'b');
      final result = await usecase.save(
        input,
        currentMember: () => member,
        expected: occurrence,
        expectedSeries: series,
        scope: CalendarChangeScope.only,
      );
      expect(result.savedId, 'event');
      expect(result.affectedGroupIds, {'a', 'b'});
      verify(
        move.execute(
          series,
          input,
          const MemberDto(id: 'self', displayName: '本人'),
        ),
      ).called(1);
      verifyZeroInteractions(change);
    });

    test('系列の版が違う場合は移動前にエラーを返す', () async {
      await expectLater(
        usecase.save(
          occurrence.copyWith(groupId: 'b'),
          currentMember: () => member,
          expected: occurrence,
          expectedSeries: series.copyWith(version: 4),
        ),
        throwsA(
          isA<ApplicationValidationException>().having(
            (e) => e.message,
            '表示メッセージ',
            '予定が変更されています。再読み込みしてからやり直してください',
          ),
        ),
      );
      verifyZeroInteractions(move);
    });

    test('本人を確認できなければ移動せずエラーを返す', () async {
      await expectLater(
        usecase.save(
          series.copyWith(groupId: 'b'),
          currentMember: () => null,
          expected: series,
        ),
        throwsA(
          isA<ApplicationValidationException>().having(
            (e) => e.message,
            '表示メッセージ',
            '利用者を確認できません。再読み込みしてください',
          ),
        ),
      );
      verifyZeroInteractions(move);
    });

    test('通常予定の削除には編集開始時のバージョンを渡す', () async {
      final result = await usecase.delete(series);
      expect(result.affectedGroupIds, {'a'});
      verify(delete.execute('event', expectedVersion: 3)).called(1);
    });

    for (final operation in ['保存', '削除']) {
      for (final mismatch in ['バージョン', '取消情報', '内容']) {
        test('$operation時に系列の$mismatchが一致しなければ書き込まずエラーを返す', () async {
          final other = switch (mismatch) {
            'バージョン' => series.copyWith(version: 4),
            '取消情報' => series.copyWith(overridesFingerprint: '別の取消情報'),
            _ => series.copyWith(title: '他者による変更'),
          };
          await expectLater(
            operation == '保存'
                ? usecase.save(
                    occurrence,
                    currentMember: () => member,
                    expected: occurrence,
                    expectedSeries: other,
                    scope: CalendarChangeScope.all,
                  )
                : usecase.delete(
                    occurrence,
                    expectedSeries: other,
                    scope: CalendarChangeScope.all,
                  ),
            throwsA(
              isA<ApplicationValidationException>().having(
                (e) => e.message,
                '表示メッセージ',
                '予定が変更されています。再読み込みしてからやり直してください',
              ),
            ),
          );
          verifyZeroInteractions(change);
          verifyZeroInteractions(update);
          verifyZeroInteractions(delete);
        });
      }
      test('$operation時に変更範囲がなければ書き込まずエラーを返す', () async {
        await expectLater(
          operation == '保存'
              ? usecase.save(
                  occurrence,
                  currentMember: () => member,
                  expected: occurrence,
                  expectedSeries: series,
                )
              : usecase.delete(occurrence, expectedSeries: series),
          throwsA(
            isA<ApplicationValidationException>().having(
              (e) => e.message,
              '表示メッセージ',
              '変更する系列を確認できません。再読み込みしてください',
            ),
          ),
        );
        verifyZeroInteractions(change);
      });
      test('$operation時に系列がなければ現在のエラーメッセージを返す', () async {
        await expectLater(
          operation == '保存'
              ? usecase.save(
                  occurrence,
                  currentMember: () => member,
                  expected: occurrence,
                  scope: CalendarChangeScope.all,
                )
              : usecase.delete(occurrence, scope: CalendarChangeScope.all),
          throwsA(
            isA<ApplicationValidationException>().having(
              (e) => e.message,
              '表示メッセージ',
              operation == '保存'
                  ? '予定が変更されています。再読み込みしてからやり直してください'
                  : '変更する系列を確認できません。再読み込みしてください',
            ),
          ),
        );
        verifyZeroInteractions(change);
      });
    }
  });
}
