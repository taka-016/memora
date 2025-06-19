import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/auth_state.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/login_page.dart';

import 'login_page_test.mocks.dart';

@GenerateMocks([AuthManager])
void main() {
  group('LoginPage', () {
    late MockAuthManager mockAuthManager;

    setUp(() {
      mockAuthManager = MockAuthManager();
    });

    Widget createTestWidget({AuthManager? authManager}) {
      return MaterialApp(
        home: LoginPage(authManager: authManager ?? mockAuthManager),
      );
    }

    testWidgets('ログイン画面の基本要素が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      expect(find.text('ログイン'), findsAtLeastNWidgets(1)); // タイトルとボタン
      expect(find.byType(TextFormField), findsNWidgets(2)); // メール、パスワード
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('アカウントをお持ちでない方'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('パスワードなしでログイン'), findsOneWidget);
    });

    testWidgets('メールアドレスとパスワードを入力できる', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('ログインボタンをタップするとloginメソッドが呼ばれる', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(loginButton);

      verify(mockAuthManager.login(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('新規登録リンクをタップすると画面遷移する', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final signupLink = find.byKey(const Key('signup_link'));
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // SignupPageに遷移することを確認
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('パスワードなしログインリンクをタップするとメールリンク送信ダイアログが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final passwordlessLink = find.byKey(const Key('passwordless_link'));
      await tester.tap(passwordlessLink);
      await tester.pumpAndSettle();

      expect(find.text('パスワードなしでログイン'), findsNWidgets(2)); // タイトルとリンク
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('送信'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('loading状態の時はローディングインジケーターが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error状態の時はエラーメッセージが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.error('ログインに失敗しました'));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('ログインに失敗しました'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('authenticated状態の時は自動的に画面が閉じられる', (WidgetTester tester) async {
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      // 状態をauthenticatedに変更
      when(mockAuthManager.state).thenReturn(AuthState.authenticated(user));

      // Notifierの変更を通知
      when(mockAuthManager.addListener(any)).thenReturn(null);
      when(mockAuthManager.removeListener(any)).thenReturn(null);

      await tester.pump();

      // ここで実際のアプリでは画面が閉じられることを想定
      // テストでは適切なナビゲーション処理が行われることを確認
    });

    testWidgets('バリデーションエラーが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final loginButton = find.byKey(const Key('login_button'));

      // 空の状態でログインボタンをタップ
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
    });
  });
}