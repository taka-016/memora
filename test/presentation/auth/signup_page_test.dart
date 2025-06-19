import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/auth_state.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/signup_page.dart';

import 'signup_page_test.mocks.dart';

@GenerateMocks([AuthManager])
void main() {
  group('SignupPage', () {
    late MockAuthManager mockAuthManager;

    setUp(() {
      mockAuthManager = MockAuthManager();
    });

    Widget createTestWidget({AuthManager? authManager}) {
      return MaterialApp(
        home: SignupPage(authManager: authManager ?? mockAuthManager),
      );
    }

    testWidgets('サインアップ画面の基本要素が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      expect(find.text('新規登録'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // メール、パスワード、確認パスワード
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('パスワード確認'), findsOneWidget);
      expect(find.text('登録'), findsOneWidget);
      expect(find.text('すでにアカウントをお持ちの方'), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('メールアドレスとパスワードを入力できる', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(const Key('confirm_password_field'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'password123');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsNWidgets(2));
    });

    testWidgets('登録ボタンをタップするとsignupメソッドが呼ばれる', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(const Key('confirm_password_field'));
      final signupButton = find.byKey(const Key('signup_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'password123');
      await tester.tap(signupButton);

      verify(mockAuthManager.signup(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('ログインリンクをタップすると画面が戻る', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final loginLink = find.byKey(const Key('login_link'));
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // 画面が戻ることを確認
      expect(find.byType(SignupPage), findsNothing);
    });

    testWidgets('loading状態の時はローディングインジケーターが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error状態の時はエラーメッセージが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.error('サインアップに失敗しました'));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('サインアップに失敗しました'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('パスワード確認のバリデーションが機能する', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final confirmPasswordField = find.byKey(const Key('confirm_password_field'));
      final signupButton = find.byKey(const Key('signup_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'different_password');
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('パスワードが一致しません'), findsOneWidget);
    });

    testWidgets('バリデーションエラーが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final signupButton = find.byKey(const Key('signup_button'));

      // 空の状態で登録ボタンをタップ
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
      expect(find.text('パスワード確認を入力してください'), findsOneWidget);
    });
  });
}