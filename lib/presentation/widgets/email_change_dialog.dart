import 'package:flutter/material.dart';
import '../../application/usecases/update_email_usecase.dart';

class EmailChangeDialog extends StatefulWidget {
  final UpdateEmailUseCase updateEmailUseCase;

  const EmailChangeDialog({super.key, required this.updateEmailUseCase});

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メールアドレスを更新しました')));
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
