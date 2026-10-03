import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/presentation/features/setting/calendar_default_duration_setting.dart';
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
  final reorder = MockReorderCalendarLabelsUsecase();
  final savedEvents = <CalendarEventDto>[];
  final savedLabels = <CalendarLabelDto>[_family];

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    when(events.execute('g1')).thenAnswer((_) async => List.of(savedEvents));
    when(labels.execute('g1')).thenAnswer((_) async => List.of(savedLabels));
    when(reorder.execute('g1', any)).thenAnswer((call) async {
      final ids = call.positionalArguments[1] as List<String>;
      final ordered = [
        for (var index = 0; index < ids.length; index++)
          savedLabels
              .firstWhere((label) => label.id == ids[index])
              .copyWith(sortOrder: index),
      ];
      savedLabels
        ..clear()
        ..addAll(ordered);
    });
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
          reorderCalendarLabelsUsecaseProvider.overrideWithValue(reorder),
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
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
    await tester.ensureVisible(find.text('16進数で指定'));
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

  testWidgets('白黒の文字色を選び背景色と名前を含むプレビューと予定表示へ反映する', (tester) async {
    final harness = _CalendarHarness()
      ..savedEvents.add(_event('e', '予定').copyWith(isAllDay: true));
    await harness.pump(tester);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族全員'));
    await tester.pumpAndSettle();
    final preview = find.byKey(const Key('calendar_label_preview'));
    Text previewText() => tester.widget<Text>(
      find.descendant(of: preview, matching: find.byType(Text)),
    );
    expect(previewText().style!.color, Colors.white);
    await tester.ensureVisible(find.text('黒'));
    await tester.tap(find.text('黒'));
    await tester.pump();
    expect(previewText().style!.color, Colors.black);
    await tester.ensureVisible(find.byTooltip('赤'));
    await tester.tap(find.byTooltip('赤'));
    await tester.pump();
    expect(
      tester.widget<Container>(preview).decoration,
      isA<BoxDecoration>().having(
        (d) => d.color,
        '背景色',
        const Color(0xFFF44336),
      ),
    );
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '全員');
    await tester.pump();
    expect(previewText().data, '全員');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(harness.savedLabels.single.textColor, '#000000');
    expect(tester.widget<Text>(find.text('全員')).style!.color, Colors.black);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('予定')).style!.color, Colors.black);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全員'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('白'));
    await tester.tap(find.text('白'));
    await tester.pump();
    expect(previewText().style!.color, Colors.white);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(harness.savedLabels.single.textColor, '#FFFFFF');
    expect(tester.takeException(), isNull);
  });

  testWidgets('任意の文字色を表示し名前だけの編集では文字色を保持する', (tester) async {
    final harness = _CalendarHarness()
      ..savedLabels[0] = _family.copyWith(textColor: '#Ab12Cd')
      ..savedEvents.add(_event('e', '予定').copyWith(isAllDay: true));
    await harness.pump(tester);
    expect(
      tester.widget<Text>(find.text('予定')).style!.color,
      const Color(0xFFAB12CD),
    );
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族全員'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '名前'), '全員');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(harness.savedLabels.single.textColor, '#Ab12Cd');
  });

  testWidgets('終日は背景と文字色、時刻付きはラベル色の文字で表示し長いタイトルを切る', (tester) async {
    const title = '非常に長いタイトルが日付枠の幅を超えている予定';
    final harness = _CalendarHarness()
      ..savedLabels[0] = _family.copyWith(textColor: '#FFFFFF')
      ..savedEvents.addAll([
        _event('all', '終日の予定').copyWith(isAllDay: true),
        _event('timed', title),
      ]);
    await harness.pump(tester);
    final allDay = tester.widget<Text>(find.text('終日の予定'));
    final timed = tester.widget<Text>(find.text(title));
    expect(allDay.style!.color, Colors.white);
    expect(timed.style!.color, const Color(0xFF123ABC));
    expect(timed.overflow, TextOverflow.clip);
    expect(timed.softWrap, isFalse);
    Container titleContainer(String title) => tester.widget<Container>(
      find
          .ancestor(of: find.text(title), matching: find.byType(Container))
          .first,
    );
    expect(
      (titleContainer('終日の予定').decoration as BoxDecoration).color,
      const Color(0xFF123ABC),
    );
    expect(
      (titleContainer(title).decoration as BoxDecoration).color,
      Colors.transparent,
    );
    await tester.tap(find.byKey(_day2));
    await tester.pump();
    await tester.tap(find.byKey(_day2));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text(title).last).style!.color,
      const Color(0xFF123ABC),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('日別一覧は画面上部まで開き一覧の追加ボタンでその日の予定を登録する', (tester) async {
    final harness = _CalendarHarness();
    await harness.pump(tester);
    await tester.tap(find.byKey(_day2));
    await tester.pump();
    await tester.tap(find.byKey(_day2));
    await tester.pumpAndSettle();
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final bounds = tester.getRect(find.byType(BottomSheet));
    expect(bounds.top, lessThan(screenHeight * .1));
    await tester.tap(find.byTooltip('この日に予定を追加'));
    await tester.pumpAndSettle();
    expect(find.text('開始日: 2026/10/2'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'タイトル'),
      '一覧から追加',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '一覧から追加'), findsOneWidget);
    expect(harness.savedEvents.single.startDateTime, DateTime(2026, 10, 2));
    await tester.tap(find.byTooltip('予定一覧を閉じる'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(_day2), matching: find.text('一覧から追加')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('小画面と拡大文字でも開始と終了の年月日・時間を横並びで操作できる', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _CalendarHarness().pump(tester, textScale: 1.5);
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, '終日'));
    await tester.pump();
    for (final prefix in ['開始', '終了']) {
      final date = find.widgetWithText(TextButton, '$prefix日: 2026/10/1');
      final time = find.byKey(
        Key('calendar_${prefix == '開始' ? 'start' : 'end'}_time'),
      );
      await tester.ensureVisible(time);
      await tester.pumpAndSettle();
      expect(tester.getCenter(date).dy, tester.getCenter(time).dy);
      expect(tester.getCenter(date).dx, lessThan(tester.getCenter(time).dx));
      await tester.tap(time);
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.text('キャンセル'),
        ),
      );
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.widgetWithText(SwitchListTile, '終日'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, '終日'));
    await tester.pump();
    expect(find.byKey(const Key('calendar_start_time')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('複数日終日予定は週ごとに連続した帯と中央のタイトルを表示する', (tester) async {
    final harness = _CalendarHarness()
      ..savedEvents.add(
        _event(
          'trip',
          '家族旅行',
        ).copyWith(isAllDay: true, endDateTime: DateTime(2026, 10, 6)),
      );
    await harness.pump(tester);
    expect(find.text('家族旅行'), findsNWidgets(2));
    for (final key in [
      'calendar_event_trip_2026_9_27',
      'calendar_event_trip_2026_10_4',
    ]) {
      final span = find.byKey(Key(key));
      final text = find.descendant(of: span, matching: find.text('家族旅行'));
      expect(tester.widget<Text>(text).textAlign, TextAlign.center);
      expect(
        tester.getSize(span).width,
        greaterThan(tester.getSize(find.byKey(_day2)).width),
      );
    }
    final day3 = find.byKey(const Key('calendar_day_2026_10_3'));
    await tester.tap(day3);
    await tester.pump();
    await tester.tap(day3);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, '家族旅行'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('番号入力を表示せず終日・時刻指定のプレビューを横並びで表示する', (tester) async {
    final harness = _CalendarHarness();
    await harness.pump(tester);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族全員'));
    await tester.pumpAndSettle();
    expect(find.text('終日'), findsOneWidget);
    expect(find.text('時間指定'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '並び順'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('calendar_label_timed_preview')),
    );
    await tester.pump();
    final allDay = tester.getRect(
      find.byKey(const Key('calendar_label_preview')),
    );
    final timed = tester.getRect(
      find.byKey(const Key('calendar_label_timed_preview')),
    );
    expect(allDay.center.dy, timed.center.dy);
    expect(allDay.right, lessThan(timed.left));

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('calendar_label_timed_preview')),
        matching: find.byType(Text),
      ),
    );
    expect(text.style!.color, const Color(0xFF123ABC));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(harness.savedLabels.single.sortOrder, _family.sortOrder);
  });

  testWidgets('ラベルをドラッグして並び替え保存後の一覧と予定入力に反映する', (tester) async {
    final harness = _CalendarHarness()
      ..savedLabels.addAll([
        _family.copyWith(id: 'child', name: '子供', sortOrder: 1),
        _family.copyWith(id: 'parent', name: '親', sortOrder: 2),
      ]);
    await harness.pump(tester);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    final firstHandle = find.byKey(const Key('calendar_label_drag_family'));
    final last = tester.getRect(find.widgetWithText(ListTile, '親'));
    final gesture = await tester.startGesture(tester.getCenter(firstHandle));
    await gesture.moveTo(Offset(last.center.dx, last.bottom + 8));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(harness.savedLabels.map((label) => label.id), [
      'child',
      'parent',
      'family',
    ]);
    verify(harness.reorder.execute('g1', ['child', 'parent', 'family']))
        .called(1);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('子供')).dy,
      lessThan(tester.getCenter(find.text('家族全員')).dy),
    );
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('予定を追加'));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.items!.map((item) => item.value), [
      'child',
      'parent',
      'family',
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final minutes in [60, 90]) {
    testWidgets('標準時間$minutes分を端末設定で保持し開始時刻から終了を自動設定する', (tester) async {
      if (minutes != 60) {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: CalendarDefaultDurationSetting()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('予定の標準時間'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, '分'),
          '$minutes',
        );
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final harness = _CalendarHarness();
      await harness.pump(tester);
      await tester.tap(find.byKey(_day2));
      await tester.pump();
      await tester.tap(find.byTooltip('予定を追加'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'タイトル'),
        '自動終了',
      );
      await tester.tap(find.widgetWithText(SwitchListTile, '終日'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calendar_start_time')));
      await tester.pumpAndSettle();
      final pickerContext = tester.element(find.byType(TimePickerDialog));
      Navigator.of(pickerContext).pop(const TimeOfDay(hour: 23, minute: 30));
      await tester.pumpAndSettle();
      expect(find.text('開始時刻: 23:30'), findsNothing);
      expect(find.text('終了日: 2026/10/3'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(
        harness.savedEvents.single.endDateTime,
        DateTime(2026, 10, 2, 23, 30).add(Duration(minutes: minutes)),
      );
    });
  }

  testWidgets('小画面と拡大文字でも配色プレビューへスクロールして保存できる', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = _CalendarHarness();
    await harness.pump(tester, textScale: 1.5);
    await tester.tap(find.byTooltip('色ラベルの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族全員'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('黒'));
    await tester.tap(find.text('黒'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('calendar_label_preview')));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(harness.savedLabels.single.textColor, '#000000');
    expect(tester.takeException(), isNull);
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
