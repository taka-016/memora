import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_notification_editor.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<ValueGetter<List<int>>> pumpEditor(
  WidgetTester tester, {
  bool allDay = false,
  List<int> initial = const [],
  double textScale = 1,
}) async {
  var values = List.of(initial);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, update) => CalendarNotificationEditor(
            allDay: allDay,
            values: values,
            onChanged: (next) => update(() => values = next),
          ),
        ),
      ),
    ),
  );
  return () => values;
}

void main() {
  testWidgets('チェック選択は最大5件で未選択項目を無効にし解除後に選び直せる', (tester) async {
    final values = await pumpEditor(tester, allDay: true);
    await tapVisible(tester, find.text('通知'));
    for (final label in ['予定の開始時', '1日前', '2日前', '1週間前', '2週間前']) {
      await tapVisible(tester, find.widgetWithText(CheckboxListTile, label));
    }
    final fourthWeek = find.widgetWithText(CheckboxListTile, '4週間前');
    expect(tester.widget<CheckboxListTile>(fourthWeek).onChanged, isNull);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '追加'))
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.widgetWithText(CheckboxListTile, '2週間前'));
    await tapVisible(tester, fourthWeek);
    expect(values(), isEmpty);
    await tapVisible(tester, find.text('決定'));
    expect(values(), [0, 1440, 2880, 10080, 40320]);
    await tapVisible(tester, find.text('通知'));
    await tapVisible(tester, find.text('通知なし'));
    await tapVisible(tester, find.text('キャンセル'));
    expect(values(), hasLength(5));
    await tapVisible(tester, find.text('通知'));
    await tapVisible(tester, find.text('通知なし'));
    await tapVisible(tester, find.text('決定'));
    expect(values(), isEmpty);
  });

  for (final setting in [
    (allDay: false, unit: '分前', maximum: 10080),
    (allDay: false, unit: '時間前', maximum: 168),
    (allDay: false, unit: '日前', maximum: 7),
    (allDay: false, unit: '週間前', maximum: 1),
    (allDay: true, unit: '日前', maximum: 28),
    (allDay: true, unit: '週間前', maximum: 4),
  ]) {
    final allDay = setting.allDay;
    testWidgets('数値と単位の入力は上限超過を拒否し上限ちょうどを保存する（終日: $allDay・${setting.unit}）', (
      tester,
    ) async {
      final values = await pumpEditor(tester, allDay: allDay);
      await tapVisible(tester, find.text('通知'));
      await tapVisible(tester, find.byType(DropdownButtonFormField<int>));
      await tapVisible(tester, find.text(setting.unit).last);
      final input = find.byType(TextField);
      await tester.ensureVisible(input);
      await tester.enterText(input, '${setting.maximum + 1}');
      await tapVisible(tester, find.widgetWithText(TextButton, '追加'));
      expect(
        find.text(allDay ? '終日の通知は4週間前まで指定できます' : '時間指定の通知は1週間前まで指定できます'),
        findsNWidgets(2),
      );
      await tester.ensureVisible(input);
      await tester.enterText(input, '${setting.maximum}');
      await tapVisible(tester, find.widgetWithText(TextButton, '追加'));
      final label = allDay ? '4週間前' : '1週間前';
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, label),
            )
            .value,
        isTrue,
      );
      // 同じタイミングを再度追加しても件数を増やさない。
      await tester.ensureVisible(input);
      await tester.enterText(input, '${setting.maximum}');
      await tapVisible(tester, find.widgetWithText(TextButton, '追加'));
      await tapVisible(tester, find.text('決定'));
      expect(values(), [allDay ? 40320 : 10080]);
    });
  }

  testWidgets('小画面と拡大文字でも候補へスクロールして選択を確定できる', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final values = await pumpEditor(tester, textScale: 1.6);
    await tapVisible(tester, find.text('通知'));
    await tapVisible(tester, find.widgetWithText(CheckboxListTile, '1週間前'));
    await tapVisible(tester, find.text('決定'));
    expect(values(), [10080]);
    expect(tester.takeException(), isNull);
  });
}
