import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/move_calendar_event_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import '../../../../helpers/test_exception.dart';
import 'calendar_mutation_coordinator_test.mocks.dart';

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
    late ProviderContainer container;
    late CalendarMutationCoordinator coordinator;
    late CalendarEventDto series;
    late CalendarEventDto occurrence;
    var refreshCount = 0;
    setUp(() {
      create = MockCreateCalendarEventUsecase();
      update = MockUpdateCalendarEventUsecase();
      delete = MockDeleteCalendarEventUsecase();
      move = MockMoveCalendarEventUsecase();
      change = MockChangeCalendarRecurrenceUsecase();
      when(change.execute(any, any, any)).thenAnswer((_) async => null);
      refreshCount = 0;
      container = ProviderContainer(
        overrides: [
          createCalendarEventUsecaseProvider.overrideWithValue(create),
          updateCalendarEventUsecaseProvider.overrideWithValue(update),
          deleteCalendarEventUsecaseProvider.overrideWithValue(delete),
          moveCalendarEventUsecaseProvider.overrideWithValue(move),
          changeCalendarRecurrenceUsecaseProvider.overrideWithValue(change),
          currentMemberNotifierProvider.overrideWith(
            () => FakeCurrentMemberNotifier.loaded(
              const MemberDto(id: 'self', displayName: '本人'),
            ),
          ),
          refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(({
            force = true,
          }) async {
            refreshCount++;
          }),
        ],
      );
      coordinator = container.read(calendarMutationCoordinatorProvider);
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
    tearDown(() => container.dispose());

    test('新規作成の保存IDを返し既存予定は更新する', () async {
      final input = series.copyWith(id: '');
      when(create.execute(input)).thenAnswer((_) async => 'created');
      expect(await coordinator.save(input), 'created');
      expect(await coordinator.save(series), 'event');
      verify(create.execute(input)).called(1);
      verify(update.execute(series)).called(1);
      expect(refreshCount, 2);
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
        expect(
          await coordinator.save(
            input,
            expected: occurrence,
            expectedSeries: series,
            scope: scope,
          ),
          'saved',
        );
        verify(
          change.execute(
            series,
            occurrence.originalStartDateTime!,
            scope,
            changes: input,
          ),
        ).called(1);
        verifyZeroInteractions(update);
        expect(refreshCount, 1);
      });
      test('繰り返し予定の削除は${scope.name}の範囲と編集開始時の系列を渡す', () async {
        await coordinator.delete(
          occurrence,
          expectedSeries: series,
          scope: scope,
        );
        verify(change.execute(series, occurrence.originalStartDateTime!, scope))
            .called(1);
        verifyZeroInteractions(delete);
        expect(refreshCount, 1);
      });
    }

    test('繰り返し予定の移動は変更範囲より優先して系列を移動する', () async {
      final input = occurrence.copyWith(groupId: 'b');
      expect(
        await coordinator.save(
          input,
          expected: occurrence,
          expectedSeries: series,
          scope: CalendarChangeScope.only,
        ),
        'event',
      );
      verify(
        move.execute(
          series,
          input,
          const MemberDto(id: 'self', displayName: '本人'),
        ),
      ).called(1);
      verifyZeroInteractions(change);
    });

    test('通常予定の削除には編集開始時のバージョンを渡す', () async {
      await coordinator.delete(series);
      verify(delete.execute('event', expectedVersion: 3)).called(1);
      expect(refreshCount, 1);
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
                ? coordinator.save(
                    occurrence,
                    expected: occurrence,
                    expectedSeries: other,
                    scope: CalendarChangeScope.all,
                  )
                : coordinator.delete(
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
          expect(refreshCount, 0);
        });
      }
      test('$operation時に変更範囲がなければ書き込まずエラーを返す', () async {
        await expectLater(
          operation == '保存'
              ? coordinator.save(
                  occurrence,
                  expected: occurrence,
                  expectedSeries: series,
                )
              : coordinator.delete(occurrence, expectedSeries: series),
          throwsA(
            isA<ApplicationValidationException>().having(
              (e) => e.message,
              '表示メッセージ',
              '変更する系列を確認できません。再読み込みしてください',
            ),
          ),
        );
        verifyZeroInteractions(change);
        expect(refreshCount, 0);
      });
      test('$operation時に系列がなければ現在のエラーメッセージを返す', () async {
        await expectLater(
          operation == '保存'
              ? coordinator.save(
                  occurrence,
                  expected: occurrence,
                  scope: CalendarChangeScope.all,
                )
              : coordinator.delete(occurrence, scope: CalendarChangeScope.all),
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
        expect(refreshCount, 0);
      });
    }
  });

  test('展開回と系列の取得時点が違う場合は新しい期待バージョンで上書きしない', () async {
    final move = MockMoveCalendarEventUsecase();
    final container = ProviderContainer(
      overrides: [
        moveCalendarEventUsecaseProvider.overrideWithValue(move),
        currentMemberNotifierProvider.overrideWith(
          () => FakeCurrentMemberNotifier.loaded(
            const MemberDto(id: 'self', displayName: '本人'),
          ),
        ),
        refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(
          ({force = true}) async {},
        ),
      ],
    );
    addTearDown(container.dispose);
    final series = CalendarEventDto(
      id: 'event',
      version: 1,
      groupId: 'a',
      labelType: 'group',
      title: '予定',
      startDateTime: DateTime.utc(2026, 11, 1),
      endDateTime: DateTime.utc(2026, 11, 2),
      isAllDay: true,
      recurrenceRule: 'FREQ=DAILY;COUNT=5',
    );
    final occurrence = series.copyWith(
      originalStartDateTime: DateTime.utc(2026, 11, 1),
    );
    await expectLater(
      container
          .read(calendarMutationCoordinatorProvider)
          .save(
            occurrence.copyWith(groupId: 'b'),
            expected: occurrence,
            expectedSeries: series.copyWith(version: 2, title: '他者の更新'),
          ),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyNever(move.execute(any, any, any));
  });
  test('移動成功後に変更前後を再取得しウィジェットを更新し失敗時は更新しない', () async {
    final calls = <String>[];
    final move = MockMoveCalendarEventUsecase();
    final container = ProviderContainer(
      overrides: [
        moveCalendarEventUsecaseProvider.overrideWithValue(move),
        currentMemberNotifierProvider.overrideWith(
          () => FakeCurrentMemberNotifier.loaded(
            const MemberDto(id: 'self', displayName: '本人'),
          ),
        ),
        refreshSelectedCalendarWidgetCacheProvider.overrideWithValue(({
          force = true,
        }) async {
          calls.add('widget');
        }),
        calendarNotifierProvider('a').overrideWith(() => _Calendar(calls)),
        calendarNotifierProvider('b').overrideWith(() => _Calendar(calls)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(calendarNotifierProvider('a'), (_, _) {});
    container.listen(calendarNotifierProvider('b'), (_, _) {});
    final source = CalendarEventDto(
      id: 'event',
      groupId: 'a',
      labelType: 'group',
      title: '予定',
      startDateTime: DateTime.utc(2026, 11, 1),
      endDateTime: DateTime.utc(2026, 11, 2),
      isAllDay: true,
    );
    final coordinator = container.read(calendarMutationCoordinatorProvider);
    await coordinator.save(source.copyWith(groupId: 'b'), expected: source);
    expect(calls.toSet(), {'a', 'b', 'widget'});
    calls.clear();
    when(move.execute(any, any, any)).thenThrow(TestException('移動失敗'));
    await expectLater(
      coordinator.save(source.copyWith(groupId: 'b'), expected: source),
      throwsA(isA<TestException>()),
    );
    expect(calls, isEmpty);
  });
}

class _Calendar extends CalendarNotifier {
  _Calendar(this.calls);
  final List<String> calls;
  @override
  CalendarState build(String groupId) =>
      CalendarState(selectedDate: DateTime(2026, 11));
  @override
  Future<void> load() async {
    calls.add(groupId);
  }
}
