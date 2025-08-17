import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value-objects/auth_state.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/auth/auth_guard.dart';
import 'package:memora/presentation/auth/login_page.dart';

import '../../../helpers/fake_auth_manager.dart';

void main() {
  group('AuthGuard', () {
    Widget createTestWidget({AuthState? authState, Widget? child}) {
      return ProviderScope(
        overrides: [
          authManagerProvider.overrideWith((ref) {
            final state = authState ?? const AuthState.unauthenticated('');
            return FakeAuthManager(state);
          }),
        ],
        child: MaterialApp(
          home: AuthGuard(child: child ?? const Text('Protected Content')),
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

      await tester.pumpWidget(
        createTestWidget(authState: AuthState.authenticated(user)),
      );
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('未認証の場合、ログイン画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.unauthenticated('')),
      );
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('loading状態の場合、ローディングインジケーターが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(authState: const AuthState.loading()),
      );
      // loading状態では処理が完了しないため、pump()を使用
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('error状態の場合、ログイン画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          authState: const AuthState.unauthenticated(
            '認証エラー',
            messageType: MessageType.error,
          ),
        ),
      );
      // すべての非同期処理とアニメーションの完了を待つ
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });
  });
}
