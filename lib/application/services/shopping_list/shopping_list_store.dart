import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';

abstract interface class ShoppingListStore {
  Stream<List<ShoppingListItem>> watchPending(String groupId);
  Future<List<ShoppingListItem>> additions(String groupId);
  Future<List<ShoppingListItem>> purchases(
    String groupId, {
    required int limit,
    ShoppingListItem? after,
  });
  Future<T> write<T>(
    String groupId,
    Future<T> Function(ShoppingListWriteScope) action,
  );
}

abstract interface class ShoppingListWriteScope {
  Future<ShoppingListItem?> read(String id);
  Future<void> save(ShoppingListItem item);
  Future<void> delete(String id);
}
