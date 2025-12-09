import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/app_logger.dart';

class EmailChangeModal extends HookWidget {
  final Function(String) onEmailChange;

  const EmailChangeModal({super.key, required this.onEmailChange});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final newEmailController = useTextEditingController();
    final isLoading = useState(false);

    Future<void> updateEmail() async {
      final currentState = formKey.currentState;
      if (currentState == null || !currentState.validate()) {
        return;
      }

      isLoading.value = true;

      try {
        await onEmailChange(newEmailController.text.trim());
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, stack) {
        logger.e(
          'EmailChangeModal._updateEmail: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'メールアドレス変更',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('newEmailField'),
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '新しいメールアドレス',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return '正しいメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading.value ? null : updateEmail,
                    child: isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
