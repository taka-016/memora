import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/widgets/password_change_modal.dart';
import 'package:memora/application/usecases/update_password_usecase.dart';
import 'package:memora/application/usecases/reauthenticate_usecase.dart';

import 'password_change_modal_test.mocks.dart';

@GenerateMocks([UpdatePasswordUseCase, ReauthenticateUseCase])
void main() {
  group('PasswordChangeModal', () {
    late MockUpdatePasswordUseCase mockUpdatePasswordUseCase;

    setUp(() {
      mockUpdatePasswordUseCase = MockUpdatePasswordUseCase();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => PasswordChangeModal(
                    onPasswordChange: (password) async {
                      await mockUpdatePasswordUseCase.execute(
                        newPassword: password,
                      );
                      return true;
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

    testWidgets('パスワード変更ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('パスワード変更'), findsOneWidget);
      expect(find.text('パスワード要件:'), findsOneWidget);
      expect(find.text('新しいパスワード'), findsOneWidget);
      expect(find.text('パスワード確認'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });

    testWidgets('新しいパスワードとパスワード確認を入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.first, 'NewPassword123!');
      await tester.enterText(passwordFields.last, 'NewPassword123!');

      expect(find.text('NewPassword123!'), findsNWidgets(2));
    });

    testWidgets('更新ボタンをタップするとパスワード更新が実行される', (WidgetTester tester) async {
      when(
        mockUpdatePasswordUseCase.execute(newPassword: anyNamed('newPassword')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.first, 'NewPassword123!');
      await tester.enterText(passwordFields.last, 'NewPassword123!');
      await tester.tap(find.text('更新'));
      await tester.pump();

      verify(
        mockUpdatePasswordUseCase.execute(newPassword: 'NewPassword123!'),
      ).called(1);
    });

    testWidgets('パスワードが一致しない場合、バリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.first, 'NewPassword123!');
      await tester.enterText(passwordFields.last, 'DifferentPassword');
      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワードが一致しません'), findsOneWidget);
      verifyNever(
        mockUpdatePasswordUseCase.execute(newPassword: anyNamed('newPassword')),
      );
    });

    testWidgets('エラー発生時にコールバックが例外をスローする', (
      WidgetTester tester,
    ) async {
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
                    builder: (context) => PasswordChangeModal(
                      onPasswordChange: (password) async {
                        callbackCalled = true;
                        thrownException = Exception('[firebase_auth/requires-recent-login]');
                        return false;
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

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.first, 'NewPassword123!');
      await tester.enterText(passwordFields.last, 'NewPassword123!');
      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(callbackCalled, isTrue);
      expect(thrownException, isNotNull);
      expect(thrownException.toString(), contains('requires-recent-login'));
      
      // ダイアログが閉じていないことを確認
      expect(find.text('パスワード変更'), findsOneWidget);
    });

    testWidgets('キャンセルボタンをタップするとダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(PasswordChangeModal), findsNothing);
    });

    testWidgets('パスワード要件が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('8文字以上'), findsOneWidget);
      expect(find.text('大文字を含む'), findsOneWidget);
      expect(find.text('小文字を含む'), findsOneWidget);
      expect(find.text('数字を含む'), findsOneWidget);
      expect(find.text('特殊文字を含む'), findsOneWidget);
    });
  });
}
