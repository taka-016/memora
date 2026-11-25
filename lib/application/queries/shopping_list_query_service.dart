import 'package:memora/application/dtos/shopping_list_item_dto.dart';

const shoppingHistoryPageSize = 30;

class ShoppingHistoryCursor {
  ShoppingHistoryCursor(this.lastItem, Set<String> names)
    : names = Set.unmodifiable(names);

  final ShoppingListItemDto lastItem;
  final Set<String> names;
}

typedef ShoppingHistoryPage = ({
  List<ShoppingListItemDto> items,
  ShoppingHistoryCursor? next,
});

abstract class ShoppingListQueryService {
  Stream<List<ShoppingListItemDto>> watchUnchecked(String groupId);
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  });
}
