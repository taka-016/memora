import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';
import 'package:memora/core/app_logger.dart';

class ReauthenticateModal extends HookConsumerWidget {
  const ReauthenticateModal({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reauthenticateUseCase = ref.read(reauthenticateUseCaseProvider);
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> authenticate() async {
      final password = passwordController.text.trim();
      if (password.isEmpty) {
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await reauthenticateUseCase.execute(password: password);
        if (context.mounted) {
          Navigator.of(context).pop(true);
          onSuccess?.call();
        }
      } catch (e, stack) {
        logger.e(
          'ReauthenticateModal._authenticate: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          errorMessage.value = e.toString().replaceFirst('Exception: ', '');
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return AlertDialog(
      title: const Text('パスワード再入力'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('操作を続行するには、現在のパスワードを入力してください'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('passwordField'),
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'パスワード',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            enabled: !isLoading.value,
          ),
          if (errorMessage.value != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage.value!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : authenticate,
          child: isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('認証'),
        ),
      ],
    );
  }
}
