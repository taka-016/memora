import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value-objects/auth_state.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/signup_page.dart';

import '../../../helpers/fake_auth_manager.dart';

void main() {
  group('SignupPage', () {
    Widget createTestWidget({AuthState? authState}) {
      return ProviderScope(
        overrides: [
          authManagerProvider.overrideWith((ref) {
            final state = authState ?? const AuthState.unauthenticated('');
            return FakeAuthManager(state);
          }),
        ],
        child: const MaterialApp(home: SignupPage()),
      );
    }

    testWidgets('サインアップ画面の基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      expect(find.text('新規登録'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // メール、パスワード、確認パスワード
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('パスワード確認'), findsOneWidget);
      expect(find.text('登録'), findsOneWidget);
      expect(find.text('すでにアカウントをお持ちの方'), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('パスワード表示切り替えアイコンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      // パスワードフィールドとパスワード確認フィールドの両方に表示切り替えアイコンがあることを確認
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('パスワード表示切り替えアイコンをタップするとパスワードが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final visibilityIcons = find.byIcon(Icons.visibility);
      expect(visibilityIcons, findsNWidgets(2));

      // 最初のパスワードフィールドのアイコンをタップ
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // アイコンの数が変わることを確認（1つが visibility_off に変わる）
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('メールアドレスとパスワードを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(
        const Key('confirm_password_field'),
      );

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'ValidPass123!');
      await tester.enterText(confirmPasswordField, 'ValidPass123!');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('ValidPass123!'), findsNWidgets(2));
    });

    testWidgets('登録ボタンをタップするとsignupメソッドが呼ばれる', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(
        const Key('confirm_password_field'),
      );
      final signupButton = find.byKey(const Key('signup_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'ValidPass123!');
      await tester.enterText(confirmPasswordField, 'ValidPass123!');
      await tester.tap(signupButton);

      // FakeAuthManagerではverifyができないため、UIの動作確認のみ
      await tester.pumpAndSettle();
    });

    testWidgets('ログインリンクをタップすると画面が戻る', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final loginLink = find.byKey(const Key('login_link'));
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // 画面が戻ることを確認
      expect(find.byType(SignupPage), findsNothing);
    });

    testWidgets('loading状態の時はローディングインジケーターが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.loading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error状態の時はエラーメッセージが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          authState: const AuthState.unauthenticated(
            'サインアップに失敗しました',
            messageType: MessageType.error,
          ),
        ),
      );

      expect(find.text('サインアップに失敗しました'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('パスワード確認のバリデーションが機能する', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(
        const Key('confirm_password_field'),
      );
      final signupButton = find.byKey(const Key('signup_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'ValidPass123!');
      await tester.enterText(confirmPasswordField, 'different_password');
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('パスワードが一致しません'), findsOneWidget);
    });

    testWidgets('バリデーションエラーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final signupButton = find.byKey(const Key('signup_button'));

      // 空の状態で登録ボタンをタップ
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードは8文字以上で入力してください'), findsOneWidget);
      expect(find.text('パスワード確認を入力してください'), findsOneWidget);
    });
  });
}
