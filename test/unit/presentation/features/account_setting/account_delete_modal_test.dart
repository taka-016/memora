import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/features/account_setting/account_delete_modal.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';

import 'account_delete_modal_test.mocks.dart';

@GenerateMocks([DeleteUserUseCase, ReauthenticateUseCase])
void main() {
  group('AccountDeleteModal', () {
    late MockDeleteUserUseCase mockDeleteUserUseCase;
    late MockReauthenticateUseCase mockReauthenticateUseCase;

    setUp(() {
      mockDeleteUserUseCase = MockDeleteUserUseCase();
      mockReauthenticateUseCase = MockReauthenticateUseCase();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AccountDeleteModal(
                    deleteUserUseCase: mockDeleteUserUseCase,
                    reauthenticateUseCase: mockReauthenticateUseCase,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('アカウント削除ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
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

    testWidgets('削除ボタンをタップするとアカウント削除が実行される', (WidgetTester tester) async {
      when(mockDeleteUserUseCase.execute()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      verify(mockDeleteUserUseCase.execute()).called(1);
    });

    testWidgets('requires-recent-loginエラー時に再認証ダイアログが表示される', (
      WidgetTester tester,
    ) async {
      when(
        mockDeleteUserUseCase.execute(),
      ).thenThrow(Exception('[firebase_auth/requires-recent-login]'));

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);
    });

    testWidgets('キャンセルボタンをタップするとダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeleteModal), findsNothing);
    });

    testWidgets('削除ボタンは赤色で表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(ElevatedButton, '削除');
      expect(deleteButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(deleteButton);
      expect(button.style?.backgroundColor?.resolve({}), Colors.red);
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    });

    testWidgets('エラー発生時にエラーメッセージが表示される', (WidgetTester tester) async {
      when(mockDeleteUserUseCase.execute()).thenThrow(Exception('削除に失敗しました'));

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      // スナックバーの表示を待つ
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('削除に失敗しました'), findsOneWidget);
    });
  });
}
