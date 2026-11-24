import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/features/shopping_list/shopping_item_add_form.dart';
import 'package:memora/presentation/features/shopping_list/shopping_list_retry.dart';
import 'package:memora/presentation/features/shopping_list/shopping_list_row.dart';
import 'package:memora/presentation/features/shopping_list/shopping_purchase_history.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/shopping_list/shopping_list_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_view.dart';

class ShoppingListScreen extends HookConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberNotifierProvider).member;
    final selection = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    final hasOpenedGroup = useRef(false);
    final isLoaded =
        member != null &&
        selection.memberId == member.id &&
        selection.status == GroupTimelineGroupSelectionStatus.loaded;
    final autoGroup = isLoaded && isCurrent && !hasOpenedGroup.value
        ? selection.groups.singleOrNull
        : null;

    useEffect(() {
      if (!isCurrent) {
        hasOpenedGroup.value = true;
      }
      if (autoGroup != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && ModalRoute.isCurrentOf(context) == true) {
            hasOpenedGroup.value = true;
            ShoppingGroupRoute(groupId: autoGroup.id).go(context);
          }
        });
      }
      return null;
    }, [isCurrent, autoGroup?.id]);

    if (member == null ||
        selection.memberId != member.id ||
        selection.status == GroupTimelineGroupSelectionStatus.loading ||
        autoGroup != null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selectionNotifier = ref.read(
      groupTimelineGroupSelectionNotifierProvider.notifier,
    );
    if (selection.status == GroupTimelineGroupSelectionStatus.error) {
      return ShoppingListRetry(
        message: selection.message,
        onRetry: () => selectionNotifier.load(member),
      );
    }

    return GroupSelectionView(
      key: const Key('shopping_list_groups'),
      groups: selection.groups,
      onGroupSelected: (group) =>
          ShoppingGroupRoute(groupId: group.id).go(context),
      onRefresh: () => selectionNotifier.refreshSilently(member),
    );
  }
}

class ShoppingGroupScreen extends HookConsumerWidget {
  const ShoppingGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberNotifierProvider).member;
    final selection = ref.watch(groupTimelineGroupSelectionNotifierProvider);
    final belongsToCurrentMember =
        member != null && selection.memberId == member.id;
    final selectedGroup = belongsToCurrentMember
        ? selection.groups.where((group) => group.id == groupId).firstOrNull
        : null;
    final missingGroup =
        belongsToCurrentMember &&
        selection.status == GroupTimelineGroupSelectionStatus.loaded &&
        selectedGroup == null;

    useEffect(() {
      if (missingGroup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          const ShoppingListRoute().go(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('指定されたグループが見つかりませんでした')),
          );
        });
      }
      return null;
    }, [groupId, missingGroup]);

    if (belongsToCurrentMember &&
        selection.status == GroupTimelineGroupSelectionStatus.error) {
      return ShoppingListRetry(
        message: selection.message,
        onRetry: () => ref
            .read(groupTimelineGroupSelectionNotifierProvider.notifier)
            .load(member),
      );
    }
    if (selectedGroup == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _ShoppingGroupList(
      key: ValueKey((member!.id, groupId)),
      groupId: groupId,
      groupName: selectedGroup.name,
    );
  }
}

class _ShoppingGroupList extends ConsumerWidget {
  const _ShoppingGroupList({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

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
              SizedBox(
                height: kMinInteractiveDimension,
                child: NavigationToolbar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '戻る',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        const ShoppingListRoute().go(context);
                      }
                    },
                  ),
                  middle: Text(
                    groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
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
                    ),
                    SliverToBoxAdapter(
                      child: ShoppingItemAddForm(groupId: groupId),
                    ),
                    items.when(
                      data: (items) => items.isEmpty
                          ? const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: Text('購入が必要な品物はありません')),
                            )
                          : SliverList.builder(
                              itemCount: items.length,
                              findChildIndexCallback: (key) {
                                final id = (key as ValueKey<String>).value;
                                final index = items.indexWhere(
                                  (item) => item.id == id,
                                );
                                return index < 0 ? null : index;
                              },
                              itemBuilder: (_, index) {
                                final item = items[index];
                                return ShoppingListRow(
                                  key: ValueKey(item.id),
                                  groupId: groupId,
                                  item: item,
                                  isChecking: checking.contains(item.id),
                                  onCheck: (current) =>
                                      _check(context, ref, current),
                                );
                              },
                            ),
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: ShoppingListRetry(
                          message: '買い物リストを読み込めませんでした。',
                          onRetry: () => ref.invalidate(provider),
                        ),
                      ),
                    ),
                  ],
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
