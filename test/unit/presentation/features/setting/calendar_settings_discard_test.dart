import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/setting/calendar_notification_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

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
