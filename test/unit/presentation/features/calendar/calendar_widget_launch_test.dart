import '../../../../helpers/calendar_group_settings_test_support.dart';

import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';

import 'dart:async';

import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/calendar_group_test_support.dart';
import '../../../../helpers/test_exception.dart';
import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';

class _WidgetDeviceCalendar extends ExternalCalendarNotifier {
  _WidgetDeviceCalendar({required this.missing});
  final bool missing;
  final ready = Completer<void>();

  @override
  ExternalCalendarState build() =>
      ExternalCalendarState(month: DateTime(2026, 11), isLoading: true);

  @override
  Future<void> setPeriod(DateTime day) async {}

  @override
  Future<void> initialize() async {
    await ready.future;
    state = ExternalCalendarState(
      month: DateTime(2026, 11),
      hasPermission: true,
      connections: [
        ExternalCalendarConnection(
          account: const ExternalCalendarAccount(
            id: 'account',
            name: 'user@example.com',
          ),
          calendarIds: {'12'},
        ),
      ],
      calendarsByAccount: {
        'account': [const ExternalCalendarDto(id: '12', name: '仕事')],
      },
      eventsByAccount: {
        'account': missing
            ? []
            : [
                ExternalCalendarEventDto(
                  accountId: 'account',
                  id: '42:1793667600000',
                  calendarId: '12',
                  calendarName: '仕事',
                  title: '端末の会議',
                  startDateTime: DateTime(2026, 11, 3, 9),
                  endDateTime: DateTime(2026, 11, 3, 10),
                  isAllDay: false,
                  memo: '会議の詳細',
                ),
              ],
      },
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scenario in [
    (externalFirst: false, missing: false),
    (externalFirst: true, missing: false),
    (externalFirst: false, missing: true),
  ]) {
    testWidgets(
      '端末予定のウィジェット起動は取得順序${scenario.externalFirst}・削除${scenario.missing}で詳細を判定する',
      (tester) async {
        final group = Completer<GroupDto?>();
        final loader = calendarTestGroupLoader();
        when(loader.execute('g1')).thenAnswer((_) => group.future);
        final events = MockGetCalendarEventsUsecase();
        final labels = MockGetCalendarLabelsUsecase();
        when(events.execute('g1', period: anyNamed('period')))
            .thenAnswer((_) async => []);
        when(labels.execute('g1')).thenAnswer((_) async => []);
        final external = _WidgetDeviceCalendar(missing: scenario.missing);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              calendarSettingsOwnerProvider.overrideWithValue('online:owner'),
              calendarGroupSettingsNotifierProvider.overrideWith(
                () => TestCalendarGroupSettingsNotifier(),
              ),
              externalCalendarOwnerProvider.overrideWithValue(null),
              externalCalendarSupportedProvider.overrideWithValue(true),
              externalCalendarNotifierProvider.overrideWith(() => external),
              appClockProvider.overrideWithValue(
                FixedAppClock(DateTime(2026, 11, 1)),
              ),
              getGroupWithMembersByIdUsecaseProvider.overrideWithValue(loader),
              getCalendarEventsUsecaseProvider.overrideWithValue(events),
              getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
              watchCalendarGroupUsecaseProvider.overrideWithValue(null),
              watchCalendarEventsUsecaseProvider.overrideWithValue(null),
              watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CalendarScreen(
                  initialEventGroupId: 'g1',
                  initialDate: DateTime(2026, 11, 3),
                  initialEventId: 'device:12:42:1793667600000',
                  initialRequest: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        if (scenario.externalFirst) external.ready.complete();
        group.complete(
          const GroupDto(id: 'g1', ownerId: 'owner', name: '家族', members: []),
        );
        await tester.pump();
        await tester.pump();
        if (!scenario.externalFirst) {
          expect(find.text('指定された予定が見つかりませんでした'), findsNothing);
          expect(find.byType(AlertDialog), findsNothing);
          external.ready.complete();
        }
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(CalendarEventDialog), findsNothing);
        if (scenario.missing) {
          expect(find.text('指定された予定が見つかりませんでした'), findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
        } else {
          expect(find.text('端末カレンダーの予定'), findsOneWidget);
          expect(find.text('会議の詳細'), findsOneWidget);
          expect(find.text('端末-user@example.com（仕事）'), findsOneWidget);
          expect(find.text('保存'), findsNothing);
          expect(find.text('削除'), findsNothing);
          await tester.tap(find.text('閉じる'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final fail in [false, true]) {
    testWidgets('ウィジェットの追加要求は入力先の読込${fail ? '失敗から再試行する' : '成功後に保存して再実行できる'}', (
      tester,
    ) async {
      final group = Completer<GroupDto?>();
      const loadedGroup = GroupDto(
        id: 'g1',
        ownerId: 'owner',
        name: '家族',
        members: [],
      );
      final loader = calendarTestGroupLoader();
      when(loader.execute('g1')).thenAnswer((_) => group.future);
      final events = MockGetCalendarEventsUsecase();
      final labels = MockGetCalendarLabelsUsecase();
      final create = MockCreateCalendarEventUsecase();
      final saved = <CalendarEventDto>[];
      when(events.execute('g1', period: anyNamed('period')))
          .thenAnswer((_) async => []);
      when(labels.execute('g1')).thenAnswer((_) async => []);
      when(create.execute(any)).thenAnswer((call) async {
        saved.add(call.positionalArguments.single as CalendarEventDto);
        return 'new';
      });
      final request = ValueNotifier(1);
      addTearDown(request.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarSettingsOwnerProvider.overrideWithValue('online:owner'),
            calendarGroupSettingsNotifierProvider.overrideWith(
              () => TestCalendarGroupSettingsNotifier(),
            ),
            externalCalendarOwnerProvider.overrideWithValue(null),
            appClockProvider.overrideWithValue(
              FixedAppClock(DateTime(2026, 10, 1)),
            ),
            getGroupWithMembersByIdUsecaseProvider.overrideWithValue(loader),
            getCalendarEventsUsecaseProvider.overrideWithValue(events),
            getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
            createCalendarEventUsecaseProvider.overrideWithValue(create),
            watchCalendarGroupUsecaseProvider.overrideWithValue(null),
            watchCalendarEventsUsecaseProvider.overrideWithValue(null),
            watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: request,
                builder: (context, value, child) => CalendarScreen(
                  initialEventGroupId: 'g1',
                  initialDate: DateTime(2026, 11, 2),
                  createEvent: true,
                  initialRequest: value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(CalendarEventDialog), findsOneWidget);
      if (fail) {
        group.completeError(TestException('読込失敗'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(CalendarEventDialog), findsOneWidget);
        when(loader.execute('g1')).thenAnswer((_) async => loadedGroup);
        await tester.tap(
          find.descendant(
            of: find.byType(CalendarEventDialog),
            matching: find.text('再試行'),
          ),
        );
      } else {
        group.complete(loadedGroup);
      }
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalendarEventDialog), findsOneWidget);
      expect(find.text('家族の予定'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'タイトル'),
        '家族旅行',
      );
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(saved.single.startDateTime, DateTime.utc(2026, 11, 2));
      expect(saved.single.labelType, 'group');
      expect(find.byType(CalendarEventDialog), findsNothing);
      request.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalendarEventDialog), findsOneWidget);
    });
  }
  for (final missing in [false, true]) {
    testWidgets(
      '予定タップ起動は${missing ? '削除済み予定を新規作成として開かない' : '読込後に指定した繰り返し予定の回を編集する'}',
      (tester) async {
        final group = Completer<GroupDto?>();
        final loader = calendarTestGroupLoader();
        when(loader.execute('g1')).thenAnswer((_) => group.future);
        final events = MockGetCalendarEventsUsecase();
        final labels = MockGetCalendarLabelsUsecase();
        when(events.execute('g1', period: anyNamed('period'))).thenAnswer(
          (_) async => [
            CalendarEventDto(
              id: 'series',
              groupId: 'g1',
              labelType: 'group',
              title: '毎日の予定',
              startDateTime: DateTime.utc(2026, 11, 1),
              endDateTime: DateTime.utc(2026, 11, 1),
              isAllDay: true,
              recurrenceRule: 'FREQ=DAILY',
            ),
          ],
        );
        when(labels.execute('g1')).thenAnswer((_) async => []);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              calendarSettingsOwnerProvider.overrideWithValue('online:owner'),
              calendarGroupSettingsNotifierProvider.overrideWith(
                () => TestCalendarGroupSettingsNotifier(),
              ),
              externalCalendarOwnerProvider.overrideWithValue(null),
              appClockProvider.overrideWithValue(
                FixedAppClock(DateTime(2026, 11, 1)),
              ),
              getGroupWithMembersByIdUsecaseProvider.overrideWithValue(loader),
              getCalendarEventsUsecaseProvider.overrideWithValue(events),
              getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
              watchCalendarGroupUsecaseProvider.overrideWithValue(null),
              watchCalendarEventsUsecaseProvider.overrideWithValue(null),
              watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CalendarScreen(
                  initialEventGroupId: 'g1',
                  initialDate: DateTime(2026, 11, 3),
                  initialRequest: 1,
                  initialEventId: missing ? 'deleted' : 'series',
                  initialOccurrence: DateTime.utc(2026, 11, 3),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byType(CalendarEventDialog), findsNothing);
        group.complete(
          const GroupDto(id: 'g1', ownerId: 'owner', name: '家族', members: []),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (missing) {
          expect(find.byType(CalendarEventDialog), findsNothing);
          expect(find.text('指定された予定が見つかりませんでした'), findsOneWidget);
        } else {
          final dialog = tester.widget<CalendarEventDialog>(
            find.byType(CalendarEventDialog),
          );
          expect(dialog.event!.id, 'series');
          expect(
            dialog.event!.originalStartDateTime,
            DateTime.utc(2026, 11, 3),
          );
          expect(dialog.event!.startDateTime, DateTime.utc(2026, 11, 3));
        }
      },
    );
  }
  testWidgets('単発予定はウィジェットの時刻が古くても同じ予定IDの最新内容で編集する', (tester) async {
    final loader = calendarTestGroupLoader();
    when(loader.execute('g1')).thenAnswer(
      (_) async =>
          const GroupDto(id: 'g1', ownerId: 'owner', name: '家族', members: []),
    );
    final events = MockGetCalendarEventsUsecase();
    final labels = MockGetCalendarLabelsUsecase();
    when(events.execute('g1', period: anyNamed('period'))).thenAnswer(
      (_) async => [
        CalendarEventDto(
          id: 'event',
          groupId: 'g1',
          labelType: 'group',
          title: '時刻変更後の予定',
          startDateTime: DateTime.utc(2026, 11, 3, 11),
          endDateTime: DateTime.utc(2026, 11, 3, 12),
          isAllDay: false,
        ),
      ],
    );
    when(labels.execute('g1')).thenAnswer((_) async => []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarSettingsOwnerProvider.overrideWithValue('online:owner'),
          calendarGroupSettingsNotifierProvider.overrideWith(
            () => TestCalendarGroupSettingsNotifier(),
          ),
          externalCalendarOwnerProvider.overrideWithValue(null),
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime(2026, 11, 1)),
          ),
          getGroupWithMembersByIdUsecaseProvider.overrideWithValue(loader),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
          watchCalendarGroupUsecaseProvider.overrideWithValue(null),
          watchCalendarEventsUsecaseProvider.overrideWithValue(null),
          watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CalendarScreen(
              initialEventGroupId: 'g1',
              initialDate: DateTime(2026, 11, 3),
              initialEventId: 'event',
              initialOccurrence: DateTime.utc(2026, 11, 3, 9),
              initialRequest: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final dialog = tester.widget<CalendarEventDialog>(
      find.byType(CalendarEventDialog),
    );
    expect(dialog.event!.title, '時刻変更後の予定');
    expect(dialog.event!.startDateTime, DateTime.utc(2026, 11, 3, 11));
  });
}
