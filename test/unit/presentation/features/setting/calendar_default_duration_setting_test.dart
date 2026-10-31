import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/setting/calendar_default_duration_setting.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSetting(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CalendarDefaultDurationSetting()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  int savedMinutes(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(CalendarDefaultDurationSetting)),
  ).read(calendarPreferencesNotifierProvider).value!.minutes;

  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('標準時間の選択とその他の有効な入力を即保存し再表示でも保持する', (tester) async {
    await pumpSetting(tester);
    for (final minutes in [5, 15, 30, 45, 60]) {
      await select(tester, '$minutes分');
      expect(savedMinutes(tester), minutes);
    }
    await select(tester, 'その他');
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(savedMinutes(tester), 60);
    expect(find.text('1〜1440分'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '75');
    await tester.pumpAndSettle();
    expect(savedMinutes(tester), 75);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpSetting(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '75',
    );
    await select(tester, '15分');
    expect(savedMinutes(tester), 15);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('キーボードを閉じるか入力欄の外をタップするとフォーカスを解除する', (tester) async {
    await pumpSetting(tester);
    await select(tester, 'その他');
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final focus = tester.widget<TextField>(find.byType(TextField)).focusNode!;
    expect(focus.hasFocus, isTrue);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pump();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.text('予定の標準時間'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
