import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';

class ShoppingListState {
  const ShoppingListState({
    this.unchecked = const AsyncLoading(),
    this.history = const ShoppingHistoryState(),
    this.saving = false,
  });

  final AsyncValue<List<ShoppingListItemDto>> unchecked;
  final ShoppingHistoryState history;
  final bool saving;

  ShoppingListState copyWith({
    AsyncValue<List<ShoppingListItemDto>>? unchecked,
    ShoppingHistoryState? history,
    bool? saving,
  }) => ShoppingListState(
    unchecked: unchecked ?? this.unchecked,
    history: history ?? this.history,
    saving: saving ?? this.saving,
  );
}

class ShoppingHistoryState {
  const ShoppingHistoryState({
    this.items = const [],
    this.next,
    this.loading = false,
    this.hasError = false,
  });

  final List<ShoppingListItemDto> items;
  final ShoppingHistoryCursor? next;
  final bool loading;
  final bool hasError;
}
