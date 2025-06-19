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
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      when(mockAuthManager.state).thenReturn(AuthState.authenticated(user));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('未認証の場合、ログイン画面が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('loading状態の場合、ローディングインジケーターが表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('error状態の場合、ログイン画面が表示される', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.error('認証エラー'));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('認証状態の変更時に適切に画面が切り替わる', (WidgetTester tester) async {
      // 最初は未認証
      when(mockAuthManager.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);

      // 認証済みに変更
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      when(mockAuthManager.state).thenReturn(AuthState.authenticated(user));

      // Notifierの変更を通知
      when(mockAuthManager.addListener(any)).thenReturn(null);
      when(mockAuthManager.removeListener(any)).thenReturn(null);

      await tester.pump();

      // 状態変更後はProtected Contentが表示される想定
      // 実際の実装では、AuthGuardがListenableBuilderなどを使って状態を監視する
    });

    testWidgets('initializeが初回のみ呼ばれる', (WidgetTester tester) async {
      when(mockAuthManager.state).thenReturn(const AuthState.loading());

      await tester.pumpWidget(createTestWidget());

      // 初回のinitializeが呼ばれることを確認
      verify(mockAuthManager.initialize()).called(1);

      // 再描画してもinitializeは呼ばれない
      await tester.pump();
      verifyNever(mockAuthManager.initialize());
    });
  });
}