import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';

import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';

void main() {
  testWidgets('ラベルがない日から名前と色を設定し予定入力の空タイトルを拒否する', (tester) async {
    final events = MockGetCalendarEventsUsecase();
    final labels = MockGetCalendarLabelsUsecase();
    final saveLabel = MockSaveCalendarLabelUsecase();
    final create = MockCreateCalendarEventUsecase();
    final saved = <CalendarLabelDto>[];
    when(events.execute('g1')).thenAnswer((_) async => []);
    when(labels.execute('g1')).thenAnswer((_) async => List.of(saved));
    when(saveLabel.execute(any)).thenAnswer((call) async {
      final label = (call.positionalArguments.single as CalendarLabelDto)
          .copyWith(id: 'family');
      saved.add(label);
      return label;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime(2026, 10, 1)),
          ),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
          saveCalendarLabelUsecaseProvider.overrideWithValue(saveLabel),
          createCalendarEventUsecaseProvider.overrideWithValue(create),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CalendarScreen(groupId: 'g1', groupName: '家族', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('予定を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ラベルを追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '家族全員');
    await tester.enterText(
      find.widgetWithText(TextFormField, '色（#RRGGBB）'),
      '赤',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('#RRGGBB形式で入力してください'), findsOneWidget);
    verifyZeroInteractions(saveLabel);
    await tester.enterText(
      find.widgetWithText(TextFormField, '色（#RRGGBB）'),
      '#FF0000',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('家族全員'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('タイトルを入力してください'), findsOneWidget);
    verifyZeroInteractions(create);
    expect(tester.takeException(), isNull);
  });
  testWidgets('空の日から共通ラベルの予定を登録し編集と削除を表示へ反映する', (tester) async {
    final events = MockGetCalendarEventsUsecase();
    final labels = MockGetCalendarLabelsUsecase();
    final create = MockCreateCalendarEventUsecase();
    final update = MockUpdateCalendarEventUsecase();
    final delete = MockDeleteCalendarEventUsecase();
    final saved = <CalendarEventDto>[];
    when(events.execute('g1')).thenAnswer((_) async => List.of(saved));
    when(labels.execute('g1')).thenAnswer(
      (_) async => [
        const CalendarLabelDto(
          id: 'family',
          groupId: 'g1',
          name: '家族全員',
          color: '#123ABC',
        ),
      ],
    );
    when(create.execute(any)).thenAnswer((call) async {
      saved.add(
        (call.positionalArguments.single as CalendarEventDto).copyWith(
          id: 'e1',
        ),
      );
      return 'e1';
    });
    when(update.execute(any)).thenAnswer((call) async {
      saved[0] = call.positionalArguments.single as CalendarEventDto;
    });
    when(delete.execute('e1')).thenAnswer((_) async {
      saved.clear();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime(2026, 10, 1)),
          ),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
          createCalendarEventUsecaseProvider.overrideWithValue(create),
          updateCalendarEventUsecaseProvider.overrideWithValue(update),
          deleteCalendarEventUsecaseProvider.overrideWithValue(delete),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CalendarScreen(groupId: 'g1', groupName: '家族', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('この日の予定はありません'), findsOneWidget);
    await tester.tap(find.text('予定を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '家族旅行');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('家族旅行'), findsOneWidget);
    expect(find.text('家族全員'), findsOneWidget);
    await tester.tap(find.text('家族旅行'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '運動会');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('運動会'), findsOneWidget);
    await tester.tap(find.text('運動会'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(find.text('この日の予定はありません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
