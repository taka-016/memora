import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';

class ShoppingHistoryDeleteButton extends StatelessWidget {
  const ShoppingHistoryDeleteButton({
    super.key,
    required this.itemName,
    required this.historyName,
    required this.onDelete,
  });

  final String itemName;
  final String historyName;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.delete_outline),
    tooltip: '$historyNameから削除',
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => _ShoppingHistoryDeleteDialog(
        itemName: itemName,
        historyName: historyName,
        onDelete: onDelete,
      ),
    ),
  );
}

class _ShoppingHistoryDeleteDialog extends HookWidget {
  const _ShoppingHistoryDeleteDialog({
    required this.itemName,
    required this.historyName,
    required this.onDelete,
  });

  final String itemName;
  final String historyName;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final deleting = useState(false);
    final message = useState<String?>(null);

    Future<void> delete() async {
      if (deleting.value) return;
      deleting.value = true;
      message.value = null;
      try {
        await onDelete();
        if (context.mounted) Navigator.of(context).pop();
      } catch (error) {
        if (context.mounted) {
          message.value = error is ApplicationValidationException
              ? error.message
              : '履歴を削除できませんでした。再試行してください。';
        }
      } finally {
        if (context.mounted) deleting.value = false;
      }
    }

    return PopScope(
      canPop: !deleting.value,
      child: AlertDialog(
        title: const Text('履歴から削除'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「$itemName」を$historyNameから削除しますか？'),
            if (message.value case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: deleting.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: deleting.value ? null : delete,
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
