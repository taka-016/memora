import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/account_settings.dart';

void main() {
  group('AccountSettings', () {
    testWidgets('アカウント設定画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccountSettings()));

      expect(find.text('アカウント設定'), findsOneWidget);
    });

    testWidgets('メールアドレス変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccountSettings()));

      expect(find.text('メールアドレス変更'), findsOneWidget);
    });

    testWidgets('パスワード変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccountSettings()));

      expect(find.text('パスワード変更'), findsOneWidget);
    });

    testWidgets('アカウント削除セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AccountSettings()));

      expect(find.text('アカウント削除'), findsOneWidget);
    });
  });
}
