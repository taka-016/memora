import 'package:flutter/material.dart';

class InvitationCodeInputModal extends StatefulWidget {
  final String? errorMessage;

  const InvitationCodeInputModal({super.key, this.errorMessage});

  @override
  State<InvitationCodeInputModal> createState() =>
      _InvitationCodeInputModalState();
}

class _InvitationCodeInputModalState extends State<InvitationCodeInputModal> {
  final _formKey = GlobalKey<FormState>();
  final _invitationCodeController = TextEditingController();

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  void _submitInvitationCode() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_invitationCodeController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('招待コード入力'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招待コードを入力してください。'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invitationCodeController,
              decoration: const InputDecoration(
                labelText: '招待コード',
                hintText: '招待コードを入力',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '招待コードを入力してください';
                }
                return null;
              },
            ),
            if (widget.errorMessage != null &&
                widget.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                widget.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(onPressed: _submitInvitationCode, child: const Text('確定')),
      ],
    );
  }
}
