import 'package:flutter/material.dart';
import '../../application/usecases/delete_user_usecase.dart';

class AccountDeleteDialog extends StatefulWidget {
  final DeleteUserUseCase deleteUserUseCase;

  const AccountDeleteDialog({super.key, required this.deleteUserUseCase});

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
