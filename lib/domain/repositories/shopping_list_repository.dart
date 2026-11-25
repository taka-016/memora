import 'package:memora/domain/entities/shopping_list_item.dart';

abstract class ShoppingListRepository {
  Future<void> add(ShoppingListItem item);
  Future<void> update(ShoppingListItem item);
  Future<void> delete(ShoppingListItem expected);
}
