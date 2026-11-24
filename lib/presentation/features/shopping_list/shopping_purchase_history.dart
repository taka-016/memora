import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  builder: (context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.6,
    ),
    child: _ShoppingPurchaseHistory(groupId: groupId),
  ),
);

class _ShoppingPurchaseHistory extends ConsumerWidget {
  const _ShoppingPurchaseHistory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = shoppingPurchasesNotifierProvider(groupId);
    final history = ref.watch(provider);
    final localizations = MaterialLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '購入済み履歴',
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
          Flexible(
            child: history.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => ShoppingListRetry(
                message: '購入済み履歴を読み込めませんでした。',
                onRetry: () => ref.invalidate(provider),
              ),
              data: (data) {
                if (data.items.isEmpty && data.nextCursor == null) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(heightFactor: 1, child: Text('購入済み履歴がありません')),
                  );
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
                    shrinkWrap: true,
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
                        trailing: ShoppingHistoryDeleteButton(
                          itemName: item.name,
                          historyName: '購入済み履歴',
                          onDelete: () => notifier.delete(item),
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
