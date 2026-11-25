import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';

ShoppingHistoryPage shoppingHistoryPage(List<ShoppingListItemDto> rows) {
  final items = rows.take(shoppingHistoryPageSize).toList();
  return (
    items: items,
    next: rows.length > shoppingHistoryPageSize
        ? ShoppingHistoryCursor(items.last)
        : null,
  );
}
