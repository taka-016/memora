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

  testWidgets('標準時間をダイアログなしで入力し検証して保存できる', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CalendarDefaultDurationSetting()),
        ),
      ),
    );
    await pumpDialog(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('保存'));
    await pumpDialog(tester);
    expect(find.text('1〜1440分で指定してください'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '75');
    await tester.tap(find.text('保存'));
    await pumpDialog(tester);
    expect(find.text('予定の標準時間を保存しました'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CalendarDefaultDurationSetting()),
        ),
      ),
    );
    await pumpDialog(tester);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
      '75',
    );
    expect(find.byType(AlertDialog), findsNothing);
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
