import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/account_setting/account_delete_modal.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  group('AccountDeleteModal', () {
    Widget createTestWidget({
      required Future<void> Function() onAccountDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      AccountDeleteModal(onAccountDelete: onAccountDelete),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('アカウント削除ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(onAccountDelete: () async {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('アカウント削除'), findsOneWidget);
      expect(
        find.text(
          'アカウントを削除すると、すべてのデータが完全に削除されます。\n'
          'この操作は取り消すことができません。\n\n'
          '本当にアカウントを削除しますか？',
        ),
        findsOneWidget,
      );
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('削除ボタンをタップするとコールバックが実行される', (WidgetTester tester) async {
      var isCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          onAccountDelete: () async {
            isCalled = true;
          },
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(isCalled, isTrue);
    });

    testWidgets('キャンセルボタンをタップするとダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(onAccountDelete: () async {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeleteModal), findsNothing);
    });

    testWidgets('削除ボタンは赤色で表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(onAccountDelete: () async {}));
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(ElevatedButton, '削除');
      expect(deleteButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(deleteButton);
      expect(button.style?.backgroundColor?.resolve({}), Colors.red);
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('エラー発生時はダイアログが閉じない', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onAccountDelete: () async {
            throw TestException('削除に失敗しました');
          },
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(find.byType(AccountDeleteModal), findsOneWidget);
    });
  });
}
