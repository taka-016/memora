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

const _day2 = Key('calendar_day_2026_10_2');
const _family = CalendarLabelDto(
  id: 'family',
  groupId: 'g1',
  name: '家族全員',
  color: '#123ABC',
);

CalendarEventDto _event(String id, String title) => CalendarEventDto(
  id: id,
  groupId: 'g1',
  labelId: 'family',
  title: title,
  startDateTime: DateTime(2026, 10, 2, 9),
  endDateTime: DateTime(2026, 10, 2, 10),
  isAllDay: false,
);

class _CalendarHarness {
  final events = MockGetCalendarEventsUsecase();
  final labels = MockGetCalendarLabelsUsecase();
  final create = MockCreateCalendarEventUsecase();
  final update = MockUpdateCalendarEventUsecase();
  final delete = MockDeleteCalendarEventUsecase();
  final saveLabel = MockSaveCalendarLabelUsecase();
  final savedEvents = <CalendarEventDto>[];
  final savedLabels = <CalendarLabelDto>[_family];

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    when(events.execute('g1')).thenAnswer((_) async => List.of(savedEvents));
    when(labels.execute('g1')).thenAnswer((_) async => List.of(savedLabels));
    when(create.execute(any)).thenAnswer((call) async {
      savedEvents.add(
        (call.positionalArguments.single as CalendarEventDto).copyWith(
          id: 'new',
        ),
      );
      return 'new';
    });
    when(update.execute(any)).thenAnswer((call) async {
      final event = call.positionalArguments.single as CalendarEventDto;
      savedEvents[savedEvents.indexWhere((item) => item.id == event.id)] =
          event;
    });
    when(delete.execute(any)).thenAnswer((call) async {
      savedEvents.removeWhere(
        (event) => event.id == call.positionalArguments.single,
      );
    });
    when(saveLabel.execute(any)).thenAnswer((call) async {
      final input = call.positionalArguments.single as CalendarLabelDto;
      final label = input.id.isEmpty ? input.copyWith(id: 'new-label') : input;
      final index = savedLabels.indexWhere((item) => item.id == label.id);
      if (index < 0) {
        savedLabels.add(label);
      } else {
        savedLabels[index] = label;
      }
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
          createCalendarEventUsecaseProvider.overrideWithValue(create),
          updateCalendarEventUsecaseProvider.overrideWithValue(update),
          deleteCalendarEventUsecaseProvider.overrideWithValue(delete),
          saveCalendarLabelUsecaseProvider.overrideWithValue(saveLabel),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: CalendarScreen(groupId: 'g1', groupName: '家族', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  testWidgets('各日の枠に先頭3件を表示し選択日の再タップで全予定と期間を確認する', (tester) async {
    final harness = _CalendarHarness()
      ..savedEvents.addAll([
        for (var i = 1; i <= 4; i++) _event('e$i', '予定$i'),
      ]);
    await harness.pump(tester);
    final cell = find.byKey(_day2);
    expect(
      find.descendant(of: cell, matching: find.text('予定1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cell, matching: find.text('予定3')),
      findsOneWidget,
    );
    expect(find.text('予定4'), findsNothing);
    expect(find.text('他1件'), findsOneWidget);
    expect(find.text('2026/10/2の予定'), findsNothing);
    await tester.tap(cell);
    await tester.pump();
    expect(find.text('2026/10/2の予定'), findsNothing);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(find.text('2026/10/2の予定'), findsOneWidget);
    expect(find.text('予定4'), findsOneWidget);
    expect(find.text('家族全員'), findsNWidgets(4));
    expect(find.text('2026/10/2 09:00 〜 2026/10/2 10:00'), findsNWidgets(4));
  });

  testWidgets('左右スワイプと矢印の両方で前月翌月へ移動する', (tester) async {
    await _CalendarHarness().pump(tester);
    final grid = find.byKey(const Key('calendar_month_grid'));
    final width = tester.getSize(grid).width;
    await tester.drag(grid, Offset(-width * .8, 0));
    await tester.pumpAndSettle();
    expect(find.text('2026年11月'), findsOneWidget);
    await tester.drag(grid, Offset(width * .8, 0));
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    await tester.tap(find.byTooltip('前の月'));
    await tester.pump();
    expect(find.text('2026年9月'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_day_2026_9_2')));
    await tester.pump();
    await tester.tap(find.byTooltip('次の月'));
    await tester.pump();
    expect(find.text('2026年10月'), findsOneWidget);
  });

  testWidgets('選択した空の日へ浮かぶ追加ボタンから登録し日別一覧で編集と削除を反映する', (tester) async {
    final harness = _CalendarHarness();
    await harness.pump(tester);
    expect(find.text('この日の予定はありません'), findsNothing);
    await tester.tap(find.byKey(_day2));
    await tester.pump();
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pumpAndSettle();
    expect(find.text('開始日: 2026/10/2'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '家族旅行');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(_day2), matching: find.text('家族旅行')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_day2));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '家族旅行'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '運動会');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '運動会'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, '運動会'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(find.text('この日の予定はありません'), findsOneWidget);
    await tester.tap(find.byTooltip('予定一覧を閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('運動会'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ラベルの色を見た目で選択して保存し16進数入力は必要なときだけ開く', (tester) async {
    final harness = _CalendarHarness()..savedLabels.clear();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ラベルを追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '家族全員');
    expect(find.widgetWithText(TextFormField, '色（#RRGGBB）'), findsNothing);
    await tester.tap(find.byTooltip('赤'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    final saved =
        verify(harness.saveLabel.execute(captureAny)).captured.single
            as CalendarLabelDto;
    expect(saved.color, '#F44336');
    await tester.tap(find.text('家族全員'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16進数で指定'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, '色（#RRGGBB）'),
      '赤',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('#RRGGBB形式で入力してください'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('青'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('青'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('タイトルを入力してください'), findsOneWidget);
    verifyZeroInteractions(harness.create);
  });

  testWidgets('小さい画面と拡大文字でも日付・追加ボタン・予定一覧を操作できる', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = _CalendarHarness()
      ..savedEvents.addAll([
        for (var i = 1; i <= 5; i++) _event('e$i', '長い予定のタイトル$i'),
      ]);
    await harness.pump(tester, textScale: 1.5);
    await tester.tap(find.byKey(_day2));
    await tester.pump();
    await tester.tap(find.byKey(_day2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, '長い予定のタイトル5'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.widgetWithText(ListTile, '長い予定のタイトル5'));
    await tester.pumpAndSettle();
    expect(find.text('予定を編集'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
