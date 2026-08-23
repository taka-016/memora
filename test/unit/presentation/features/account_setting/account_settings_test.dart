import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/exceptions/reauthentication_required_exception.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/presentation/features/account_setting/account_delete_modal.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/account_setting/email_change_modal.dart';
import 'package:memora/presentation/features/account_setting/password_change_modal.dart';
import '../../../../helpers/test_exception.dart';

class _TestAuthService implements AuthService {
  _TestAuthService({
    List<Future<void> Function()>? updateEmailBehaviors,
    List<Future<void> Function()>? updatePasswordBehaviors,
    List<Future<void> Function()>? deleteUserBehaviors,
  }) : _updateEmailBehaviors = updateEmailBehaviors ?? [() async {}],
       _updatePasswordBehaviors = updatePasswordBehaviors ?? [() async {}],
       _deleteUserBehaviors = deleteUserBehaviors ?? [() async {}];

  final List<Future<void> Function()> _updateEmailBehaviors;
  final List<Future<void> Function()> _updatePasswordBehaviors;
  final List<Future<void> Function()> _deleteUserBehaviors;
  int _updateEmailIndex = 0;
  int _updatePasswordIndex = 0;
  int _deleteUserIndex = 0;

  int updateEmailCallCount = 0;
  int updatePasswordCallCount = 0;
  int deleteUserCallCount = 0;
  int reauthenticateCallCount = 0;
  Future<void> Function(String password)? onReauthenticate;

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Stream<User?> get authStateChanges => Stream<User?>.empty();

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> deleteUser() async {
    deleteUserCallCount++;
    if (_deleteUserIndex < _deleteUserBehaviors.length) {
      final behavior = _deleteUserBehaviors[_deleteUserIndex];
      _deleteUserIndex++;
      await behavior();
    }
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    reauthenticateCallCount++;
    await onReauthenticate?.call(password);
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {
    updateEmailCallCount++;
    if (_updateEmailIndex < _updateEmailBehaviors.length) {
      final behavior = _updateEmailBehaviors[_updateEmailIndex];
      _updateEmailIndex++;
      await behavior();
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatePasswordCallCount++;
    if (_updatePasswordIndex < _updatePasswordBehaviors.length) {
      final behavior = _updatePasswordBehaviors[_updatePasswordIndex];
      _updatePasswordIndex++;
      await behavior();
    }
  }

  @override
  Future<void> validateCurrentUserToken() async {}
}

Widget _buildTestApp(Widget child, {_TestAuthService? authService}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService ?? _TestAuthService()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AccountSettings', () {
    testWidgets('アカウント設定画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('アカウント設定'), findsOneWidget);
    });

    testWidgets('メールアドレス変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('メールアドレス変更'), findsOneWidget);
    });

    testWidgets('パスワード変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('パスワード変更'), findsOneWidget);
    });

    testWidgets('アカウント削除セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('アカウント削除'), findsOneWidget);
    });

    testWidgets('メールアドレス変更が成功するとスナックバーが表示される', (WidgetTester tester) async {
      final authService = _TestAuthService();

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 1);
      expect(find.byType(EmailChangeModal), findsNothing);
      expect(
        find.text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
        findsOneWidget,
      );
    });

    testWidgets('アカウント削除が成功するとスナックバーが表示される', (WidgetTester tester) async {
      final authService = _TestAuthService();

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('アカウント削除'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(authService.deleteUserCallCount, 1);
      expect(find.byType(AccountDeleteModal), findsNothing);
      expect(find.text('アカウントを削除しました'), findsOneWidget);
    });

    testWidgets('パスワード変更が成功するとスナックバーが表示される', (WidgetTester tester) async {
      final authService = _TestAuthService();

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('パスワード変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newPasswordField')),
        'NewPassword123#',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'NewPassword123#',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(authService.updatePasswordCallCount, 1);
      expect(find.byType(PasswordChangeModal), findsNothing);
      expect(find.text('パスワードを更新しました'), findsOneWidget);
    });

    testWidgets('メールアドレス変更で再認証が必要な場合は再認証モーダルが表示される', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async {},
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(EmailChangeModal), findsNothing);
      expect(
        find.text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
        findsOneWidget,
      );
    });

    testWidgets('アカウント削除で再認証が必要な場合は再認証モーダルが表示される', (WidgetTester tester) async {
      final authService = _TestAuthService(
        deleteUserBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async {},
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('アカウント削除'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.deleteUserCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(AccountDeleteModal), findsNothing);
      expect(find.text('アカウントを削除しました'), findsOneWidget);
    });

    testWidgets('パスワード変更で再認証が必要な場合は再認証モーダルが表示される', (WidgetTester tester) async {
      final authService = _TestAuthService(
        updatePasswordBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async {},
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('パスワード変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newPasswordField')),
        'NewPassword123#',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'NewPassword123#',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.updatePasswordCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(PasswordChangeModal), findsNothing);
      expect(find.text('パスワードを更新しました'), findsOneWidget);
    });

    testWidgets('メールアドレス変更で再認証後もエラーの場合はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async => throw TestException('再試行に失敗しました'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(EmailChangeModal), findsOneWidget);
      expect(
        find.text('エラーが発生しました: TestException: 再試行に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('アカウント削除で再認証後もエラーの場合はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        deleteUserBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async => throw TestException('再試行に失敗しました'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('アカウント削除'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'password123');
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.deleteUserCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(AccountDeleteModal), findsOneWidget);
      expect(
        find.text('エラーが発生しました: TestException: 再試行に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('パスワード変更で再認証後もエラーの場合はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updatePasswordBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async => throw TestException('再試行に失敗しました'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('パスワード変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newPasswordField')),
        'NewPassword123#',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'NewPassword123#',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(find.text('パスワード再入力'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pumpAndSettle();

      expect(authService.updatePasswordCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(PasswordChangeModal), findsOneWidget);
      expect(
        find.text('エラーが発生しました: TestException: 再試行に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('メールアドレス変更で再認証不要のエラー時はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async => throw TestException('メールアドレス変更に失敗しました'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailChangeModal), findsOneWidget);
      expect(
        find.text('エラーが発生しました: TestException: メールアドレス変更に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('アカウント削除で再認証不要のエラー時はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        deleteUserBehaviors: [() async => throw TestException('削除に失敗しました')],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('アカウント削除'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeleteModal), findsOneWidget);
      expect(find.text('エラーが発生しました: TestException: 削除に失敗しました'), findsOneWidget);
    });

    testWidgets('パスワード変更で再認証不要のエラー時はエラースナックバーが表示されダイアログが残る', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updatePasswordBehaviors: [
          () async => throw TestException('パスワード変更に失敗しました'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );

      await tester.tap(find.text('パスワード変更'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('newPasswordField')),
        'NewPassword123#',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'NewPassword123#',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(find.byType(PasswordChangeModal), findsOneWidget);
      expect(
        find.text('エラーが発生しました: TestException: パスワード変更に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('例外メッセージに認証期限切れコードが含まれていても型が異なる場合は再認証しない', (
      WidgetTester tester,
    ) async {
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async =>
              throw TestException('[firebase_auth/requires-recent-login]'),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );
      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 1);
      expect(authService.reauthenticateCallCount, 0);
      expect(find.text('パスワード再入力'), findsNothing);
      expect(
        find.text(
          'エラーが発生しました: '
          'TestException: [firebase_auth/requires-recent-login]',
        ),
        findsOneWidget,
      );
    });

    testWidgets('再認証をキャンセルすると入力ダイアログを維持し再度更新できる', (WidgetTester tester) async {
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () async {},
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );
      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.tap(find.text('更新'));
      await tester.pump();

      await tester.tap(find.widgetWithText(TextButton, 'キャンセル').last);
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 1);
      expect(authService.reauthenticateCallCount, 0);
      expect(find.byType(EmailChangeModal), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 2);
      expect(find.byType(EmailChangeModal), findsNothing);
      expect(
        find.text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
        findsOneWidget,
      );
    });

    testWidgets('再認証に失敗すると更新を再試行せず再認証ダイアログへエラーを表示する', (
      WidgetTester tester,
    ) async {
      final authService =
          _TestAuthService(
              updatePasswordBehaviors: [
                () async => throw const ReauthenticationRequiredException(),
              ],
            )
            ..onReauthenticate = (_) async {
              throw TestException('再認証に失敗しました');
            };

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );
      await tester.tap(find.text('パスワード変更'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newPasswordField')),
        'NewPassword123#',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'NewPassword123#',
      );
      await tester.tap(find.text('更新'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );

      await tester.tap(find.text('認証'));
      await tester.pump();
      await tester.pump();

      expect(authService.updatePasswordCallCount, 1);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.text('パスワード再入力'), findsOneWidget);
      expect(find.text('Test再認証に失敗しました'), findsOneWidget);
      expect(find.text('パスワードを更新しました'), findsNothing);
    });

    testWidgets('更新中に入力ダイアログを閉じると完了後に再認証を表示しない', (WidgetTester tester) async {
      final updateCompleter = Completer<void>();
      final authService = _TestAuthService(
        updateEmailBehaviors: [() => updateCompleter.future],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );
      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.tap(find.text('更新'));
      await tester.pump();

      expect(authService.updateEmailCallCount, 1);
      expect(
        find.descendant(
          of: find.byType(EmailChangeModal),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      updateCompleter.completeError(
        const ReauthenticationRequiredException(),
        StackTrace.current,
      );
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 1);
      expect(authService.reauthenticateCallCount, 0);
      expect(find.text('パスワード再入力'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('再試行中に入力ダイアログを閉じると完了後に成功表示を行わない', (WidgetTester tester) async {
      final retryCompleter = Completer<void>();
      final authService = _TestAuthService(
        updateEmailBehaviors: [
          () async => throw const ReauthenticationRequiredException(),
          () => retryCompleter.future,
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(const AccountSettings(), authService: authService),
      );
      await tester.tap(find.text('メールアドレス変更'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('newEmailField')),
        'newemail@example.com',
      );
      await tester.tap(find.text('更新'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.text('認証'));
      await tester.pump();
      await tester.pump();

      expect(authService.updateEmailCallCount, 2);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      retryCompleter.complete();
      await tester.pumpAndSettle();

      expect(authService.updateEmailCallCount, 2);
      expect(authService.reauthenticateCallCount, 1);
      expect(find.byType(EmailChangeModal), findsNothing);
      expect(
        find.text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
        findsNothing,
      );
    });
  });
}
