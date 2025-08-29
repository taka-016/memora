import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/features/account_setting/email_change_modal.dart';
import 'package:memora/application/usecases/update_email_usecase.dart';
import 'package:memora/application/usecases/reauthenticate_usecase.dart';

import 'email_change_modal_test.mocks.dart';

@GenerateMocks([UpdateEmailUseCase, ReauthenticateUseCase])
void main() {
  group('EmailChangeModal', () {
    late MockUpdateEmailUseCase mockUpdateEmailUseCase;

    setUp(() {
      mockUpdateEmailUseCase = MockUpdateEmailUseCase();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EmailChangeModal(
                    onEmailChange: (email) async {
                      await mockUpdateEmailUseCase.execute(newEmail: email);
                    },
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

    testWidgets('エラー発生時にコールバックが例外をスローする', (WidgetTester tester) async {
      bool callbackCalled = false;
      Exception? thrownException;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EmailChangeModal(
                      onEmailChange: (email) async {
                        callbackCalled = true;
                        thrownException = Exception(
                          '[firebase_auth/requires-recent-login]',
                        );
                        throw thrownException!;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'newemail@example.com');
      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(callbackCalled, isTrue);
      expect(thrownException, isNotNull);
      expect(thrownException.toString(), contains('requires-recent-login'));
    });
  });
}
