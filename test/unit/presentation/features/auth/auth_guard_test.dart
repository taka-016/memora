import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:memora/composition_root/providers/account_providers.dart';
import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';
import '../../notifiers/auth/auth_notifier_test.mocks.dart';
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

class _InvitationAuth extends FakeAuthNotifier {
  _InvitationAuth() : super(const AuthState.unauthenticated(memberSelectionRequiredMessage));
  Completer<bool> ready = Completer<bool>();
  final codes = <String>[];
  @override
  Future<bool> acceptInvitation(String invitationCode, {required String userId}) {
    codes.add(invitationCode);
    return ready.future;
  }
}

class _FailedAvailability extends AppAvailabilityNotifier {
  @override
  AppAvailabilityState build() => const AppAvailabilityState(hasError: true);
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

    testWidgets('招待承諾の確認中と確認失敗後も同じダイアログと入力を保持して再試行する', (tester) async {
      const user = UserDto(id: 'user', loginId: 'test@example.com', isVerified: true);
      final current = MockGetCurrentUserUseCase();
      when(current.execute()).thenAnswer((_) async => user);
      final auth = _InvitationAuth();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => auth),
          getCurrentUserUseCaseProvider.overrideWithValue(current),
          appAvailabilityNotifierProvider.overrideWith(_FailedAvailability.new),
        ],
        child: const MaterialApp(home: AuthGuard(child: Text('アプリ本体'))),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('招待コード入力'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextFormField), '招待コード123');
      await tester.tap(find.text('確定'));
      await tester.pump();
      expect(find.text('招待コード123'), findsOneWidget);
      await tester.tap(find.text('確定'));
      expect(auth.codes, ['招待コード123']);
      auth.ready.complete(false);
      await tester.pump();
      expect(find.text('招待コード123'), findsOneWidget);
      expect(find.textContaining('利用状況'), findsOneWidget);
      expect(find.text('招待コードが無効です。'), findsNothing);
      auth.ready = Completer<bool>();
      await tester.tap(find.text('確定'));
      await tester.pump();
      expect(auth.codes, ['招待コード123', '招待コード123']);
      auth.ready.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TextFormField), findsNothing);
    });

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
