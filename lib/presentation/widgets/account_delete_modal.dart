import 'package:flutter/material.dart';
import '../../application/usecases/delete_user_usecase.dart';
import '../../application/usecases/reauthenticate_usecase.dart';
import 'reauthenticate_modal.dart';

class AccountDeleteModal extends StatefulWidget {
  final DeleteUserUseCase deleteUserUseCase;
  final ReauthenticateUseCase reauthenticateUseCase;

  const AccountDeleteModal({
    super.key,
    required this.deleteUserUseCase,
    required this.reauthenticateUseCase,
  });

  @override
  State<AccountDeleteModal> createState() => _AccountDeleteModalState();
}

class _AccountDeleteModalState extends State<AccountDeleteModal> {
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
      builder: (context) => ReauthenticateModal(
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
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle() {
    return const Text('アカウント削除');
  }

  Widget _buildContent() {
    return const Text(
      'アカウントを削除すると、すべてのデータが完全に削除されます。\n'
      'この操作は取り消すことができません。\n\n'
      '本当にアカウントを削除しますか？',
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [_buildCancelButton(context), _buildDeleteButton()];
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      child: const Text('キャンセル'),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _deleteAccount,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      child: _isLoading ? _buildLoadingIndicator() : const Text('削除'),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
