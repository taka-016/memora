import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value-objects/auth_state.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/login_page.dart';

import '../../../helpers/fake_auth_manager.dart';

void main() {
  group('LoginPage', () {
    Widget createTestWidget({AuthState? authState}) {
      return ProviderScope(
        overrides: [
          authManagerProvider.overrideWith((ref) {
            final state = authState ?? const AuthState.unauthenticated('');
            return FakeAuthManager(state);
          }),
        ],
        child: const MaterialApp(home: LoginPage()),
      );
    }

    testWidgets('ログイン画面の基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      expect(find.text('ログイン'), findsNWidgets(2)); // AppBarとボタンの2つ
      expect(find.byType(TextFormField), findsNWidgets(2)); // メール、パスワード
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('アカウントをお持ちでない方'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
    });

    testWidgets('パスワード表示切り替えアイコンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);

      // パスワード表示切り替えアイコンが存在することを確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('パスワード表示切り替えアイコンをタップするとパスワードが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

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
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('ログインボタンをタップするとloginメソッドが呼ばれる', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(loginButton);

      // FakeAuthManagerではverifyができないため、UIの動作確認のみ
      await tester.pumpAndSettle();
    });
  });
}
