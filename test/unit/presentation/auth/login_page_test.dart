import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/auth_state.dart';
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

      expect(find.text('ログイン'), findsNWidgets(2)); // AppBarとボタンの2つ
      expect(find.byType(TextFormField), findsNWidgets(2)); // メール、パスワード
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('アカウントをお持ちでない方'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
    });

    testWidgets('パスワード表示切り替えアイコンが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);

      // パスワード表示切り替えアイコンが存在することを確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('パスワード表示切り替えアイコンをタップするとパスワードが表示される', (
      WidgetTester tester,
    ) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      final visibilityIcon = find.byIcon(Icons.visibility);

      // 初期状態では visibility アイコンが表示される
      expect(visibilityIcon, findsOneWidget);

      // アイコンをタップ
      await tester.tap(visibilityIcon);
      await tester.pump();

      // アイコンが visibility_off に変わる
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // もう一度タップすると元に戻る
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
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

      verify(
        mockAuthManager.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });
}
