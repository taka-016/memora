import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/account/update_email_usecase.dart';
import 'package:memora/application/usecases/account/update_password_usecase.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';
import 'email_change_modal.dart';
import 'password_change_modal.dart';
import 'account_delete_modal.dart';
import 'reauthenticate_modal.dart';
import 'package:memora/core/app_logger.dart';

class AccountSettings extends ConsumerWidget {
  const AccountSettings({super.key});

  Future<void> _showEmailChangeModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final updateEmailUseCase = ref.read(updateEmailUseCaseProvider);
    final reauthenticateUseCase = ref.read(reauthenticateUseCaseProvider);

    await showDialog(
      context: context,
      builder: (context) => EmailChangeModal(
        onEmailChange: (newEmail) async {
          try {
            await updateEmailUseCase.execute(newEmail: newEmail);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } catch (e, stack) {
            logger.e(
              'AccountSettings._showEmailChangeModal.onEmailChange: ${e.toString()}',
              error: e,
              stackTrace: stack,
            );
            if (e.toString().contains('requires-recent-login')) {
              if (!context.mounted) return;
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => ReauthenticateModal(
                  reauthenticateUseCase: reauthenticateUseCase,
                ),
              );
              if (result == true && context.mounted) {
                await updateEmailUseCase.execute(newEmail: newEmail);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
                );
              }
            }
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _showPasswordChangeModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final updatePasswordUseCase = ref.read(updatePasswordUseCaseProvider);
    final reauthenticateUseCase = ref.read(reauthenticateUseCaseProvider);

    await showDialog(
      context: context,
      builder: (context) => PasswordChangeModal(
        onPasswordChange: (newPassword) async {
          try {
            await updatePasswordUseCase.execute(newPassword: newPassword);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('パスワードを更新しました')));
            }
          } catch (e, stack) {
            logger.e(
              'AccountSettings._showPasswordChangeModal.onPasswordChange: ${e.toString()}',
              error: e,
              stackTrace: stack,
            );
            if (e.toString().contains('requires-recent-login')) {
              if (!context.mounted) return;
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => ReauthenticateModal(
                  reauthenticateUseCase: reauthenticateUseCase,
                ),
              );
              if (result == true && context.mounted) {
                await updatePasswordUseCase.execute(newPassword: newPassword);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('パスワードを更新しました')));
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
                );
              }
            }
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _showAccountDeleteModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final deleteUserUseCase = ref.read(deleteUserUseCaseProvider);
    final reauthenticateUseCase = ref.read(reauthenticateUseCaseProvider);

    await showDialog(
      context: context,
      builder: (context) => AccountDeleteModal(
        deleteUserUseCase: deleteUserUseCase,
        reauthenticateUseCase: reauthenticateUseCase,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント設定')),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return Padding(
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
