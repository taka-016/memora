import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/app_logger.dart';

class AccountDeleteModal extends HookWidget {
  final Future<void> Function() onAccountDelete;

  const AccountDeleteModal({super.key, required this.onAccountDelete});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    Future<void> deleteAccount() async {
      isLoading.value = true;

      try {
        await onAccountDelete();

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, stack) {
        logger.e(
          'AccountDeleteModal._deleteAccount: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    Widget buildLoadingIndicator() {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return AlertDialog(
      title: const Text('アカウント削除'),
      content: const Text(
        'アカウントを削除すると、すべてのデータが完全に削除されます。\n'
        'この操作は取り消すことができません。\n\n'
        '本当にアカウントを削除しますか？',
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: isLoading.value ? buildLoadingIndicator() : const Text('削除'),
        ),
      ],
    );
  }
}
