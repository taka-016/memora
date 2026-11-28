import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InvitationCodeInputDialog extends HookWidget {
  final Future<String?> Function(String code) onSubmit;

  const InvitationCodeInputDialog({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final invitationCodeController = useTextEditingController();

    final errorMessage = useState<String?>(null);
    final isSubmitting = useState(false);

    Future<void> submitInvitationCode() async {
      if (isSubmitting.value || !formKey.currentState!.validate()) return;
      isSubmitting.value = true;
      try {
        final error = await onSubmit(invitationCodeController.text.trim());
        if (!context.mounted) return;
        if (error == null) {
          Navigator.of(context).pop(true);
        } else {
          errorMessage.value = error;
        }
      } finally {
        if (context.mounted) isSubmitting.value = false;
      }
    }

    return PopScope(
      canPop: !isSubmitting.value,
      child: AlertDialog(
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
                enabled: !isSubmitting.value,
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
              if (errorMessage.value != null &&
                  errorMessage.value!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage.value!,
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
            onPressed: isSubmitting.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: isSubmitting.value ? null : submitInvitationCode,
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}
