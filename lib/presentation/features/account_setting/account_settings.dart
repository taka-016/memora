import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/exceptions/reauthentication_required_exception.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/usecases/account/update_email_usecase.dart';
import 'package:memora/application/usecases/account/update_password_usecase.dart';
import 'account_delete_modal.dart';
import 'email_change_modal.dart';
import 'password_change_modal.dart';
import 'reauthenticate_modal.dart';

typedef _AccountUpdateModalBuilder =
    Widget Function(BuildContext dialogContext, _AccountUpdateSession session);

class AccountSettings extends ConsumerWidget {
  const AccountSettings({super.key});

  Future<void> _showUpdateModal({
    required BuildContext context,
    required _AccountUpdateModalBuilder builder,
  }) async {
    final session = _AccountUpdateSession();
    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => builder(dialogContext, session),
      );
    } finally {
      session.close();
    }
  }

  Future<void> _showEmailChangeModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _showUpdateModal(
      context: context,
      builder: (dialogContext, session) => EmailChangeModal(
        onEmailChange: (newEmail) => _handleEmailChange(
          context: dialogContext,
          ref: ref,
          session: session,
          newEmail: newEmail,
        ),
      ),
    );
  }

  Future<bool> _handleEmailChange({
    required BuildContext context,
    required WidgetRef ref,
    required _AccountUpdateSession session,
    required String newEmail,
  }) async {
    final updateEmailUseCase = ref.read(updateEmailUseCaseProvider);
    return _executeAccountUpdate(
      context: context,
      session: session,
      update: () => updateEmailUseCase.execute(newEmail: newEmail),
      successMessage: '確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。',
      successMessageDuration: const Duration(seconds: 5),
    );
  }

  Future<void> _showPasswordChangeModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _showUpdateModal(
      context: context,
      builder: (dialogContext, session) => PasswordChangeModal(
        onPasswordChange: (newPassword) => _handlePasswordChange(
          context: dialogContext,
          ref: ref,
          session: session,
          newPassword: newPassword,
        ),
      ),
    );
  }

  Future<bool> _handlePasswordChange({
    required BuildContext context,
    required WidgetRef ref,
    required _AccountUpdateSession session,
    required String newPassword,
  }) async {
    final updatePasswordUseCase = ref.read(updatePasswordUseCaseProvider);
    return _executeAccountUpdate(
      context: context,
      session: session,
      update: () => updatePasswordUseCase.execute(newPassword: newPassword),
      successMessage: 'パスワードを更新しました',
    );
  }

  Future<void> _showAccountDeleteModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await _showUpdateModal(
      context: context,
      builder: (dialogContext, session) => AccountDeleteModal(
        onAccountDelete: () => _handleAccountDelete(
          context: dialogContext,
          ref: ref,
          session: session,
        ),
      ),
    );
  }

  Future<bool> _handleAccountDelete({
    required BuildContext context,
    required WidgetRef ref,
    required _AccountUpdateSession session,
  }) async {
    final deleteUserUseCase = ref.read(deleteUserUseCaseProvider);
    return _executeAccountUpdate(
      context: context,
      session: session,
      update: deleteUserUseCase.execute,
      successMessage: 'アカウントを削除しました',
    );
  }

  Future<bool> _executeAccountUpdate({
    required BuildContext context,
    required _AccountUpdateSession session,
    required Future<void> Function() update,
    required String successMessage,
    Duration? successMessageDuration,
  }) async {
    try {
      final didUpdate = await session.execute(
        update: update,
        reauthenticate: () {
          if (!context.mounted) {
            return Future<bool?>.value(false);
          }
          return showDialog<bool>(
            context: context,
            builder: (context) => const ReauthenticateModal(),
          );
        },
      );
      if (!didUpdate || !context.mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: successMessageDuration ?? const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (e) {
      if (session.isActive && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: ${e.toString()}')));
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmailChangeCard(context, ref),
            const SizedBox(height: 16),
            _buildPasswordChangeCard(context, ref),
            const SizedBox(height: 16),
            _buildAccountDeleteCard(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailChangeCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.email),
        title: const Text('メールアドレス変更'),
        subtitle: const Text('現在のメールアドレスを変更'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showEmailChangeModal(context, ref),
      ),
    );
  }

  Widget _buildPasswordChangeCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock),
        title: const Text('パスワード変更'),
        subtitle: const Text('現在のパスワードを変更'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showPasswordChangeModal(context, ref),
      ),
    );
  }

  Widget _buildAccountDeleteCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('アカウント削除', style: TextStyle(color: Colors.red)),
        subtitle: const Text('アカウントを完全に削除'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showAccountDeleteModal(context, ref),
      ),
    );
  }
}

class _AccountUpdateSession {
  bool _isActive = true;
  bool _isRunning = false;

  bool get isActive => _isActive;

  void close() {
    _isActive = false;
  }

  Future<bool> execute({
    required Future<void> Function() update,
    required Future<bool?> Function() reauthenticate,
  }) async {
    if (!_isActive || _isRunning) {
      return false;
    }

    _isRunning = true;
    try {
      try {
        await update();
      } on ReauthenticationRequiredException {
        if (!_isActive) {
          return false;
        }

        final didReauthenticate = await reauthenticate();
        if (didReauthenticate != true || !_isActive) {
          return false;
        }

        await update();
      }
      return _isActive;
    } finally {
      _isRunning = false;
    }
  }
}
