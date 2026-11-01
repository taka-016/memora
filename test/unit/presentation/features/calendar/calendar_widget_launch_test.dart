import 'dart:async';

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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final fail in [false, true]) {
    testWidgets('ウィジェットの追加要求は読込${fail ? '失敗時には開かず再試行する' : '成功後に初期ラベルと選択日を使い再実行できる'}', (tester) async {
      final group = Completer<GroupDto?>();
      const loadedGroup = GroupDto(id: 'g1', ownerId: 'owner', name: '家族', members: []);
      final loader = calendarTestGroupLoader();
      when(loader.execute('g1')).thenAnswer((_) => group.future);
      final events = MockGetCalendarEventsUsecase();
      final labels = MockGetCalendarLabelsUsecase();
      final create = MockCreateCalendarEventUsecase();
      final saved = <CalendarEventDto>[];
      when(events.execute('g1')).thenAnswer((_) async => []);
      when(labels.execute('g1')).thenAnswer((_) async => []);
      when(create.execute(any)).thenAnswer((call) async {
        saved.add(call.positionalArguments.single as CalendarEventDto);
        return 'new';
      });
      final request = ValueNotifier(1);
      addTearDown(request.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FixedAppClock(DateTime(2026, 10, 1))),
          getGroupWithMembersByIdUsecaseProvider.overrideWithValue(loader),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
          createCalendarEventUsecaseProvider.overrideWithValue(create),
          watchCalendarGroupUsecaseProvider.overrideWithValue(null),
          watchCalendarEventsUsecaseProvider.overrideWithValue(null),
          watchCalendarLabelsUsecaseProvider.overrideWithValue(null),
        ],
        child: MaterialApp(home: Scaffold(body: ValueListenableBuilder<int>(
          valueListenable: request,
          builder: (context, value, child) => CalendarScreen(
            groupId: 'g1', groupName: '家族', onBack: () {},
            initialDate: DateTime(2026, 11, 2), createEvent: true,
            initialRequest: value,
          ),
        ))),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CalendarEventDialog), findsNothing);
      if (fail) {
        group.completeError(TestException('読込失敗'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(CalendarEventDialog), findsNothing);
        when(loader.execute('g1')).thenAnswer((_) async => loadedGroup);
        await tester.tap(find.text('再試行'));
      } else {
        group.complete(loadedGroup);
      }
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalendarEventDialog), findsOneWidget);
      expect(find.text('グループの予定'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '家族旅行');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(saved.single.startDateTime, DateTime(2026, 11, 2));
      expect(saved.single.labelType, 'group');
      expect(find.byType(CalendarEventDialog), findsNothing);
      request.value++;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalendarEventDialog), findsOneWidget);
    });
  }
}
