import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/setting/calendar_default_duration_setting.dart';
import 'package:memora/presentation/features/setting/calendar_notification_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('カレンダーの標準時間は変更がある場合だけ共通の破棄確認を出す', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CalendarDefaultDurationSetting()),
        ),
      ),
    );
    await pumpDialog(tester);
    await tester.tap(find.text('予定の標準時間'));
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextFormField), '75');
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('編集を続ける'));
    await pumpDialog(tester);
    await tester.enterText(find.byType(TextFormField), '60');
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('60分'), findsOneWidget);
  });
  testWidgets('デフォルト通知の変更を破棄すると保存せず元の設定を保つ', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CalendarNotificationSetting())),
      ),
    );
    await pumpDialog(tester);
    await tester.tap(find.text('予定の通知設定'));
    await pumpDialog(tester);
    await tester.tap(find.text('通知を追加').first);
    await pumpDialog(tester);
    await tester.tap(find.text('予定の開始時'));
    await pumpDialog(tester);
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsOneWidget);
    await tester.tap(find.text('破棄する'));
    await pumpDialog(tester);
    await tester.tap(find.text('予定の通知設定'));
    await pumpDialog(tester);
    expect(find.text('通知なし'), findsNWidgets(2));
    await tester.tap(find.text('キャンセル'));
    await pumpDialog(tester);
    expect(find.text('変更内容の確認'), findsNothing);
  });
}
