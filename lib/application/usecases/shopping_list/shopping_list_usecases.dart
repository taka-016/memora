import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/mappers/shopping_list_item_mapper.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';

class WatchUncheckedShoppingItemsUseCase {
  const WatchUncheckedShoppingItemsUseCase(this._query);
  final ShoppingListQueryService _query;

  Stream<List<ShoppingListItemDto>> execute(String groupId) =>
      _query.watchUnchecked(groupId);
}

class GetShoppingHistoryUseCase {
  const GetShoppingHistoryUseCase(this._query);
  final ShoppingListQueryService _query;

  Future<ShoppingHistoryPage> execute(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) => _query.getHistory(groupId, after: after);
}

class AddShoppingItemUseCase {
  const AddShoppingItemUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(String groupId, String name, String quantity) =>
      _repository.add(
        ShoppingListItem(
          id: const Uuid().v4(),
          groupId: groupId,
          name: name,
          quantity: quantity,
        ),
      );

  Future<void> registerFromHistory(ShoppingListItemDto item) {
    final expected = ShoppingListItemMapper.toEntity(item);
    return _repository.update(expected, expected.register(''));
  }
}

class EditShoppingItemUseCase {
  const EditShoppingItemUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item, String name, String quantity) {
    final expected = ShoppingListItemMapper.toEntity(item);
    return _repository.update(expected, expected.edit(name, quantity));
  }
}

class DeleteShoppingItemUseCase {
  const DeleteShoppingItemUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item) {
    final expected = ShoppingListItemMapper.toEntity(item);
    final removed = expected.removeFromList();
    return removed.purchasedAt == null
        ? _repository.delete(expected)
        : _repository.update(expected, removed);
  }
}

class CheckShoppingItemUseCase {
  const CheckShoppingItemUseCase(this._repository, this._clock);
  final ShoppingListRepository _repository;
  final AppClock _clock;

  Future<ShoppingListItemDto> execute(ShoppingListItemDto item) async {
    final expected = ShoppingListItemMapper.toEntity(item);
    final checked = expected.check(_clock.now());
    await _repository.update(expected, checked);
    return ShoppingListItemMapper.toDto(checked);
  }
}

class UndoShoppingItemCheckUseCase {
  const UndoShoppingItemCheckUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item, DateTime? previousPurchase) {
    final expected = ShoppingListItemMapper.toEntity(item);
    return _repository.update(expected, expected.undoCheck(previousPurchase));
  }
}

class DeleteShoppingHistoryUseCase {
  const DeleteShoppingHistoryUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item) {
    final expected = ShoppingListItemMapper.toEntity(item);
    final cleared = expected.clearPurchase();
    return cleared.isListed
        ? _repository.update(expected, cleared)
        : _repository.delete(expected);
  }
}
