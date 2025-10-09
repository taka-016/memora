import 'package:flutter/material.dart';
import 'package:memora/core/app_logger.dart';

class AccountDeleteModal extends StatefulWidget {
  final Future<void> Function() onAccountDelete;

  const AccountDeleteModal({super.key, required this.onAccountDelete});

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
      await widget.onAccountDelete();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      logger.e(
        'AccountDeleteModal._deleteAccount: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
