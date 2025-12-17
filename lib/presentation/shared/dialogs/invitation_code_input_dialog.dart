import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InvitationCodeInputDialog extends HookWidget {
  final String? errorMessage;

  const InvitationCodeInputDialog({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final invitationCodeController = useTextEditingController();

    void submitInvitationCode() {
      if (formKey.currentState!.validate()) {
        Navigator.of(context).pop(invitationCodeController.text.trim());
      }
    }

    return AlertDialog(
      title: const Text('招待コード入力'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招待コードを入力してください。'),
            const SizedBox(height: 16),
            TextFormField(
              controller: invitationCodeController,
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
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
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
        TextButton(onPressed: submitInvitationCode, child: const Text('確定')),
      ],
    );
  }
}
