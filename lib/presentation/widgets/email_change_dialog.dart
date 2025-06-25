import 'package:flutter/material.dart';
import '../../application/usecases/update_email_usecase.dart';
import '../../application/usecases/reauthenticate_usecase.dart';
import 'reauthenticate_dialog.dart';

class EmailChangeDialog extends StatefulWidget {
  final UpdateEmailUseCase updateEmailUseCase;
  final ReauthenticateUseCase reauthenticateUseCase;

  const EmailChangeDialog({
    super.key,
    required this.updateEmailUseCase,
    required this.reauthenticateUseCase,
  });

  @override
  State<EmailChangeDialog> createState() => _EmailChangeDialogState();
}

class _EmailChangeDialogState extends State<EmailChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.updateEmailUseCase.execute(
        newEmail: _newEmailController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
            duration: Duration(seconds: 5),
          ),
        );
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
      // 再認証成功後にメールアドレス変更を再実行（再帰を避けるため直接実行）
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.updateEmailUseCase.execute(
          newEmail: _newEmailController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
              duration: Duration(seconds: 5),
            ),
          );
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
      title: const Text('メールアドレス変更'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '新しいメールアドレス',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'メールアドレスを入力してください';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return '正しいメールアドレスを入力してください';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateEmail,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('更新'),
        ),
      ],
    );
  }
}
