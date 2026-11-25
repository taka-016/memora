import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';

class ShoppingListItemMapper {
  static ShoppingListItemDto toDto(ShoppingListItem item) =>
      ShoppingListItemDto(
        id: item.id,
        groupId: item.groupId,
        name: item.name,
        quantity: item.quantity,
        isListed: item.isListed,
        purchasedAt: item.purchasedAt,
        version: item.version,
      );

  static ShoppingListItem toEntity(ShoppingListItemDto item) =>
      ShoppingListItem(
        id: item.id,
        groupId: item.groupId,
        name: item.name,
        quantity: item.quantity,
        isListed: item.isListed,
        purchasedAt: item.purchasedAt,
        version: item.version,
      );
}
