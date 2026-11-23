import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/features/shopping_list/shopping_item_dialog.dart';
import 'package:memora/presentation/features/shopping_list/shopping_list_retry.dart';
import 'package:memora/presentation/features/shopping_list/shopping_purchase_history.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/shopping_list/shopping_list_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

class ShoppingListScreen extends HookConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberNotifierProvider).member;
    final selection = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final selectedGroupId = useState<String?>(null);
    if (member == null ||
        selection.memberId != member.id ||
        selection.status == GroupTimelineGroupSelectionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (selection.status == GroupTimelineGroupSelectionStatus.error) {
      return ShoppingListRetry(
        message: selection.message,
        onRetry: () => ref
            .read(groupTimelineGroupSelectionNotifierProvider.notifier)
            .load(member),
      );
    }
    final groups = selection.groups;
    if (groups.isEmpty) {
      return const Center(
        key: Key('shopping_list_groups'),
        child: Text('所属グループがありません'),
      );
    }
    final groupId = groups.length == 1
        ? groups.single.id
        : groups
              .where((group) => group.id == selectedGroupId.value)
              .firstOrNull
              ?.id;
    return Column(
      key: const Key('shopping_list_groups'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: DropdownButton<String>(
            isExpanded: true,
            hint: const Text('グループを選択'),
            value: groupId,
            onChanged: (value) => selectedGroupId.value = value,
            items: [
              for (final group in groups)
                DropdownMenuItem(
                  value: group.id,
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
        if (groupId != null)
          Expanded(
            child: _ShoppingGroupList(
              key: ValueKey((member.id, groupId)),
              groupId: groupId,
            ),
          ),
      ],
    );
  }
}

class _ShoppingGroupList extends ConsumerWidget {
  const _ShoppingGroupList({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = pendingShoppingListProvider(groupId);
    final items = ref.watch(provider);
    final checking = ref.watch(
      shoppingListNotifierProvider(groupId)
          .select((state) => state.checkingItemIds),
    );
    return ScaffoldMessenger(
      child: Scaffold(
        body: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '買い物リスト',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          showShoppingPurchaseHistory(context, groupId),
                      icon: const Icon(Icons.history),
                      label: const Text('購入済み履歴'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.when(
                  data: (items) => items.isEmpty
                      ? const Center(child: Text('購入が必要な品物はありません'))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, index) {
                            final item = items[index];
                            final isChecking = checking.contains(item.id);
                            return ListTile(
                              leading: Checkbox(
                                value: false,
                                semanticLabel: '${item.name}を購入済みにする',
                                onChanged: isChecking
                                    ? null
                                    : (_) => _check(context, ref, item),
                              ),
                              title: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(item.name)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(item.pendingQuantity!)),
                                ],
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: isChecking
                                  ? null
                                  : () => showShoppingItemDialog(
                                      context,
                                      groupId,
                                      item: item,
                                    ),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => ShoppingListRetry(
                    message: '買い物リストを読み込めませんでした。',
                    onRetry: () => ref.invalidate(provider),
                  ),
                ),
              ),
              if (items.hasValue)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed: () => showShoppingItemDialog(context, groupId),
                      icon: const Icon(Icons.add),
                      label: const Text('品物を追加'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _check(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
  ) async {
    final list = ref.read(shoppingListProvider);
    final notifier = ref.read(shoppingListNotifierProvider(groupId).notifier);
    try {
      final checked = await notifier.check(item);
      if (checked == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${item.name}を購入済みにしました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () async {
              try {
                await list.undo(groupId, item, checked);
              } catch (error) {
                if (context.mounted) {
                  _showError(context, error, 'チェックを元に戻せませんでした。');
                }
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        _showError(context, error, 'チェックを保存できませんでした。再試行してください。');
      }
    }
  }

  void _showError(BuildContext context, Object error, String fallback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ApplicationValidationException ? error.message : fallback,
        ),
      ),
    );
  }
}
