import 'package:memora/application/dtos/shopping_list_item_dto.dart';

const shoppingHistoryPageSize = 30;

class ShoppingHistoryCursor {
  const ShoppingHistoryCursor(this.lastItem);

  final ShoppingListItemDto lastItem;
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
