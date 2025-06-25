import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/widgets/email_change_dialog.dart';
import 'package:memora/application/usecases/update_email_usecase.dart';
import 'package:memora/application/usecases/reauthenticate_usecase.dart';

import 'email_change_dialog_test.mocks.dart';

@GenerateMocks([UpdateEmailUseCase, ReauthenticateUseCase])
void main() {
  group('EmailChangeDialog', () {
    late MockUpdateEmailUseCase mockUpdateEmailUseCase;
    late MockReauthenticateUseCase mockReauthenticateUseCase;

    setUp(() {
      mockUpdateEmailUseCase = MockUpdateEmailUseCase();
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
                  builder: (context) => EmailChangeDialog(
                    updateEmailUseCase: mockUpdateEmailUseCase,
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

    testWidgets('メール変更ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('メールアドレス変更'), findsOneWidget);
      expect(find.text('新しいメールアドレス'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('新しいメールアドレスを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'newemail@example.com');

      expect(find.text('newemail@example.com'), findsOneWidget);
    });

    testWidgets('更新ボタンをタップするとメール更新が実行される', (WidgetTester tester) async {
      when(
        mockUpdateEmailUseCase.execute(newEmail: anyNamed('newEmail')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'newemail@example.com');
      await tester.tap(find.text('更新'));
      await tester.pump();

      verify(
        mockUpdateEmailUseCase.execute(newEmail: 'newemail@example.com'),
      ).called(1);
    });

    testWidgets('requires-recent-loginエラー時に再認証ダイアログが表示される', (
      WidgetTester tester,
    ) async {
      when(
        mockUpdateEmailUseCase.execute(newEmail: anyNamed('newEmail')),
      ).thenThrow(Exception('[firebase_auth/requires-recent-login]'));

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'newemail@example.com');
      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);
    });
  });
}
