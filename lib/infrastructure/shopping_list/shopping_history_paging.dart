import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';

Future<ShoppingHistoryPage> readShoppingHistoryPage(
  ShoppingHistoryCursor? after,
  Future<List<ShoppingListItemDto>> Function(ShoppingListItemDto? after)
  readBatch,
) async {
  final names = {...?after?.names};
  final items = <ShoppingListItemDto>[];
  var position = after?.lastItem;
  while (true) {
    final batch = await readBatch(position);
    for (final item in batch) {
      if (!names.contains(item.name)) {
        if (items.length == shoppingHistoryPageSize) {
          return (items: items, next: ShoppingHistoryCursor(position!, names));
        }
        names.add(item.name);
        items.add(item);
      }
      position = item;
    }
    if (batch.length < shoppingHistoryPageSize) {
      return (items: items, next: null);
    }
  }
}
