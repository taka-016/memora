import 'package:flutter/material.dart';
import '../../../core/app_logger.dart';

class EmailChangeModal extends StatefulWidget {
  final Function(String) onEmailChange;

  const EmailChangeModal({super.key, required this.onEmailChange});

  @override
  State<EmailChangeModal> createState() => _EmailChangeModalState();
}

class _EmailChangeModalState extends State<EmailChangeModal> {
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
      await widget.onEmailChange(_newEmailController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      logger.e(
        'EmailChangeModal._updateEmail: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      // エラーハンドリングは呼び出し側で行う
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: _buildDialogContent(),
    );
  }

  Widget _buildDialogContent() {
    return Material(
      type: MaterialType.card,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 20),
            _buildEmailForm(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'メールアドレス変更',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildEmailForm() {
    return Form(
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildCancelButton(),
        const SizedBox(width: 8),
        _buildUpdateButton(),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      child: const Text('キャンセル'),
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateEmail,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('更新'),
    );
  }
}
