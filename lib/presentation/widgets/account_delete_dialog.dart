import 'package:flutter/material.dart';
import '../../application/usecases/delete_user_usecase.dart';
import '../../application/usecases/reauthenticate_usecase.dart';
import 'reauthenticate_dialog.dart';

class AccountDeleteDialog extends StatefulWidget {
  final DeleteUserUseCase deleteUserUseCase;
  final ReauthenticateUseCase reauthenticateUseCase;

  const AccountDeleteDialog({
    super.key,
    required this.deleteUserUseCase,
    required this.reauthenticateUseCase,
  });

  @override
  State<AccountDeleteDialog> createState() => _AccountDeleteDialogState();
}

class _AccountDeleteDialogState extends State<AccountDeleteDialog> {
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deleteUserUseCase.execute();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('アカウントを削除しました')));
      }
    } catch (e) {
      if (mounted) {
        // requires-recent-loginエラーの場合は再認証ダイアログを表示
        if (e.toString().contains('requires-recent-login')) {
          await _showReauthenticateDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showReauthenticateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReauthenticateDialog(
        reauthenticateUseCase: widget.reauthenticateUseCase,
      ),
    );

    if (result == true && mounted) {
      // 再認証成功後にアカウント削除を再実行（再帰を避けるため直接実行）
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.deleteUserUseCase.execute();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('アカウントを削除しました')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('アカウント削除'),
      content: const Text(
        'アカウントを削除すると、すべてのデータが完全に削除されます。\n'
        'この操作は取り消すことができません。\n\n'
        '本当にアカウントを削除しますか？',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('削除'),
        ),
      ],
    );
  }
}
