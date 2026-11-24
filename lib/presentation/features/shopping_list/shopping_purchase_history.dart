import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/features/shopping_list/shopping_item_dialog.dart';
import 'package:memora/presentation/features/shopping_list/shopping_history_delete_button.dart';
import 'package:memora/presentation/features/shopping_list/shopping_list_retry.dart';
import 'package:memora/presentation/notifiers/shopping_list/shopping_list_notifier.dart';

Future<void> showShoppingPurchaseHistory(
  BuildContext context,
  String groupId,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.85,
    child: _ShoppingPurchaseHistory(groupId: groupId),
  ),
);

class _ShoppingPurchaseHistory extends HookConsumerWidget {
  const _ShoppingPurchaseHistory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shoppingPurchasesNotifierProvider(groupId);
    final history = ref.watch(provider);
    final localizations = MaterialLocalizations.of(context);
    final registering = useState(false);
    final message = useState<String?>(null);

    Future<void> registerAgain(ShoppingListItem item) async {
      if (registering.value) return;
      final route = ModalRoute.of(context);
      final list = ref.read(shoppingListProvider);
      registering.value = true;
      message.value = null;
      try {
        final existing = await list.add(groupId, item.name, '');
        if (!context.mounted || route?.isCurrent != true) return;
        if (existing != null) {
          final edited = await showShoppingItemEditDialog(
            context,
            groupId,
            item: existing,
            editQuantityOnly: true,
          );
          if (!context.mounted || route?.isCurrent != true || edited != true) {
            return;
          }
        }
        Navigator.of(context).pop();
      } catch (error) {
        if (context.mounted && route?.isCurrent == true) {
          message.value = error is ApplicationValidationException
              ? error.message
              : '品物を再登録できませんでした。再試行してください。';
        }
      } finally {
        if (context.mounted) registering.value = false;
      }
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '購入履歴',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (message.value case final error?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ShoppingListRetry(
                message: '購入履歴を読み込めませんでした。',
                onRetry: () => ref.invalidate(provider),
              ),
              data: (data) {
                if (data.items.isEmpty && data.nextCursor == null) {
                  return const Center(child: Text('購入履歴がありません'));
                }
                final notifier = ref.read(provider.notifier);
                return NotificationListener<ScrollEndNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter == 0 &&
                        !data.hasError &&
                        data.nextCursor != null) {
                      notifier.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount:
                        data.items.length + (data.nextCursor != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == data.items.length) {
                        return data.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : TextButton(
                                onPressed: notifier.loadMore,
                                child: Text(
                                  data.hasError ? '読み込めませんでした。再読み込み' : 'さらに表示',
                                ),
                              );
                      }
                      final item = data.items[index];
                      final time = item.purchasedAt!.toLocal();
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(flex: 2, child: Text(item.name)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.purchasedQuantity!)),
                          ],
                        ),
                        subtitle: Text(
                          '${localizations.formatCompactDate(time)} '
                          '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: registering.value
                                  ? null
                                  : () => registerAgain(item),
                              child: const Text('再登録'),
                            ),
                            ShoppingHistoryDeleteButton(
                              itemName: item.name,
                              historyName: '購入履歴',
                              onDelete: registering.value
                                  ? null
                                  : () => notifier.delete(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
