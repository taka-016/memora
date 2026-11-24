import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_notifier.g.dart';

Duration? _noRetry(int _, Object _) => null;

@Riverpod(retry: _noRetry)
Stream<List<ShoppingListItem>> pendingShoppingList(Ref ref, String groupId) =>
    ref.watch(shoppingListProvider).watchPending(groupId);

class ShoppingListState {
  const ShoppingListState({this.checkingItemIds = const {}});

  final Set<String> checkingItemIds;
}

@riverpod
class ShoppingListNotifier extends _$ShoppingListNotifier {
  @override
  ShoppingListState build(String groupId) => const ShoppingListState();

  Future<ShoppingListItem?> check(ShoppingListItem item) async {
    if (state.checkingItemIds.contains(item.id)) return null;
    state = ShoppingListState(
      checkingItemIds: Set.unmodifiable({...state.checkingItemIds, item.id}),
    );
    try {
      return await ref.read(shoppingListProvider).check(groupId, item);
    } finally {
      if (ref.mounted) {
        state = ShoppingListState(
          checkingItemIds: Set.unmodifiable(
            {...state.checkingItemIds}..remove(item.id),
          ),
        );
      }
    }
  }
}

class ShoppingPurchasesState {
  ShoppingPurchasesState(
    List<ShoppingListItem> items, {
    required this.nextCursor,
    this.isLoading = false,
    this.hasError = false,
  }) : items = List.unmodifiable(items);

  final List<ShoppingListItem> items;
  final ShoppingListItem? nextCursor;
  final bool isLoading;
  final bool hasError;
}

@Riverpod(retry: _noRetry)
class ShoppingPurchasesNotifier extends _$ShoppingPurchasesNotifier {
  @override
  Future<ShoppingPurchasesState> build(String groupId) async {
    final items = await ref.watch(shoppingListProvider).purchases(groupId);
    return _withPage([], items);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.nextCursor == null || current.isLoading) {
      return;
    }
    state = AsyncData(
      ShoppingPurchasesState(
        current.items,
        nextCursor: current.nextCursor,
        isLoading: true,
      ),
    );
    final operationRef = ref;
    try {
      final page = await ref
          .read(shoppingListProvider)
          .purchases(groupId, after: current.nextCursor);
      if (operationRef.mounted) {
        state = AsyncData(_withPage(current.items, page));
      }
    } catch (_) {
      if (operationRef.mounted) {
        state = AsyncData(
          ShoppingPurchasesState(
            current.items,
            nextCursor: current.nextCursor,
            hasError: true,
          ),
        );
      }
    }
  }

  ShoppingPurchasesState _withPage(
    List<ShoppingListItem> items,
    List<ShoppingListItem> page,
  ) {
    final existingNames = items.map((item) => item.name).toSet();
    return ShoppingPurchasesState(
      [...items, ...page.where((item) => !existingNames.contains(item.name))],
      nextCursor: page.length == ShoppingList.PURCHASE_PAGE_SIZE
          ? page.last
          : null,
    );
  }
}
