import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/auth_state.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/auth_guard.dart';
import 'package:memora/presentation/auth/login_page.dart';

import 'auth_guard_test.mocks.dart';

@GenerateMocks([AuthManager])
void main() {
  group('AuthGuard', () {
    late MockAuthManager mockAuthManager;

    setUp(() {
      mockAuthManager = MockAuthManager();
      // ListenableBuilderで使用されるメソッドをモック
      when(mockAuthManager.addListener(any)).thenReturn(null);
      when(mockAuthManager.removeListener(any)).thenReturn(null);
      // initializeメソッドをモック（非同期完了）
      when(mockAuthManager.initialize()).thenAnswer((_) async {});
    });

    Widget createTestWidget({AuthManager? authManager, Widget? child}) {
      return MaterialApp(
        home: AuthGuard(
          authManager: authManager ?? mockAuthManager,
          child: child ?? const Text('Protected Content'),
        ),
      );
    }

    testWidgets('認証済みの場合、子ウィジェットが表示される', (WidgetTester tester) async {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      when(mockAuthManager.state).thenReturn(AuthState.authenticated(user));

      await tester.pumpWidget(createTestWidget());
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('未認証の場合、ログイン画面が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('loading状態の場合、ローディングインジケーターが表示される', (
      WidgetTester tester,
    ) async {
      when(mockAuthManager.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createTestWidget());
      // loading状態では処理が完了しないため、pump()を使用
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('error状態の場合、ログイン画面が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.error('認証エラー'));

      await tester.pumpWidget(createTestWidget());
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });
  });
}
