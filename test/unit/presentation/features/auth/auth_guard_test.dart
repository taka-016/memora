import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/features/auth/auth_guard.dart';
import 'package:memora/presentation/features/auth/login_page.dart';

import '../../../../helpers/fake_auth_notifier.dart';

class _RetryAuth extends FakeAuthNotifier {
  _RetryAuth() : super(const AuthState.initializationFailed('通信待ちです'));
  int retries = 0;

  @override
  Future<void> retryInitialization() async {
    retries++;
    state = const AuthState.loading();
  }

  void finish() {
    state = const AuthState.authenticated(
      UserDto(id: 'user', loginId: 'test@example.com', isVerified: true),
    );
  }
}

void main() {
  group('AuthGuard', () {
    Widget createTestWidget({AuthState? authState, Widget? child}) {
      return ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(
              authState ?? const AuthState.unauthenticated(''),
            ),
          ),
        ],
        child: MaterialApp(
          home: AuthGuard(child: child ?? const Text('Protected Content')),
        ),
      );
    }

    testWidgets('通信タイムアウトの再試行から確認中を経て保護された画面へ進む', (tester) async {
      final auth = _RetryAuth();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authNotifierProvider.overrideWith(() => auth)],
          child: const MaterialApp(
            home: AuthGuard(child: Text('Protected Content')),
          ),
        ),
      );
      expect(find.text('通信待ちです'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      await tester.tap(find.text('再試行'));
      await tester.pump();
      expect(auth.retries, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      auth.finish();
      await tester.pump();
      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('認証済みの場合、子ウィジェットが表示される', (WidgetTester tester) async {
      const user = UserDto(
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
