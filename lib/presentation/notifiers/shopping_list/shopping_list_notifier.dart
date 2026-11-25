import 'dart:async';

import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/presentation/notifiers/shopping_list/shopping_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_notifier.g.dart';

@riverpod
class ShoppingListNotifier extends _$ShoppingListNotifier {
  StreamSubscription<List<ShoppingListItemDto>>? _subscription;
  int _subscriptionGeneration = 0;
  int _historyGeneration = 0;

  @override
  ShoppingListState build(String groupId) {
    ref.watch(watchUncheckedShoppingItemsUseCaseProvider);
    ref.onDispose(() {
      _subscriptionGeneration++;
      _historyGeneration++;
      unawaited(_subscription?.cancel());
    });
    final generation = _subscriptionGeneration;
    scheduleMicrotask(() {
      if (ref.mounted && generation == _subscriptionGeneration) {
        watchUnchecked();
      }
    });
    return const ShoppingListState();
  }

  void watchUnchecked() {
    final generation = ++_subscriptionGeneration;
    unawaited(_subscription?.cancel());
    state = state.copyWith(unchecked: const AsyncLoading());
    _subscription = ref
        .read(watchUncheckedShoppingItemsUseCaseProvider)
        .execute(groupId)
        .listen(
          (items) {
            if (generation == _subscriptionGeneration) {
              state = state.copyWith(
                unchecked: AsyncData(List.unmodifiable(items)),
              );
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (generation == _subscriptionGeneration) {
              state = state.copyWith(unchecked: AsyncError(error, stackTrace));
            }
          },
        );
  }

  Future<void> loadHistory({bool refresh = false}) async {
    final current = state.history;
    if (!refresh &&
        (current.loading ||
            (current.next == null && current.items.isNotEmpty))) {
      return;
    }
    final generation = ++_historyGeneration;
    final previous = refresh ? const ShoppingHistoryState() : current;
    state = state.copyWith(
      history: ShoppingHistoryState(
        items: previous.items,
        next: previous.next,
        loading: true,
      ),
    );
    try {
      final page = await ref
          .read(getShoppingHistoryUseCaseProvider)
          .execute(groupId, after: previous.next);
      if (generation != _historyGeneration) return;
      state = state.copyWith(
        history: ShoppingHistoryState(
          items: List.unmodifiable([...previous.items, ...page.items]),
          next: page.next,
        ),
      );
    } catch (_) {
      if (generation != _historyGeneration) return;
      state = state.copyWith(
        history: ShoppingHistoryState(
          items: previous.items,
          next: previous.next,
          hasError: true,
        ),
      );
    }
  }

  Future<T> _save<T>(Future<T> Function() save) async {
    if (state.saving) {
      throw const ApplicationValidationException('保存が完了してから再試行してください');
    }
    state = state.copyWith(saving: true);
    try {
      return await save();
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }

  Future<void> add(String name, String quantity) => _save(
    () => ref
        .read(addShoppingItemUseCaseProvider)
        .execute(groupId, name, quantity),
  );

  Future<void> edit(ShoppingListItemDto item, String name, String quantity) =>
      _save(
        () => ref
            .read(editShoppingItemUseCaseProvider)
            .execute(item, name, quantity),
      );

  Future<void> delete(ShoppingListItemDto item) =>
      _save(() => ref.read(deleteShoppingItemUseCaseProvider).execute(item));

  Future<ShoppingListItemDto> check(ShoppingListItemDto item) =>
      _save(() => ref.read(checkShoppingItemUseCaseProvider).execute(item));

  Future<void> undoCheck(
    ShoppingListItemDto item,
    DateTime? previousPurchase,
  ) => _save(
    () => ref
        .read(undoShoppingItemCheckUseCaseProvider)
        .execute(item, previousPurchase),
  );

  Future<void> deleteHistory(ShoppingListItemDto item) => _save(() async {
    await ref.read(deleteShoppingHistoryUseCaseProvider).execute(item);
    if (ref.mounted) await loadHistory(refresh: true);
  });
}
