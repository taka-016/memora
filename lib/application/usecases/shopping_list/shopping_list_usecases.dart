import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
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
}

class EditShoppingItemUseCase {
  const EditShoppingItemUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(
    ShoppingListItemDto item,
    String name,
    String quantity,
  ) => _repository.update(
    ShoppingListItemMapper.toEntity(item).edit(name, quantity),
  );
}

class DeleteShoppingItemUseCase {
  const DeleteShoppingItemUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item) {
    if (item.purchasedAt != null) {
      throw const ApplicationValidationException('未チェックの品物を指定してください');
    }
    return _repository.delete(ShoppingListItemMapper.toEntity(item));
  }
}

class CheckShoppingItemUseCase {
  const CheckShoppingItemUseCase(this._repository, this._clock);
  final ShoppingListRepository _repository;
  final AppClock _clock;

  Future<ShoppingListItemDto> execute(ShoppingListItemDto item) async {
    final checked = ShoppingListItemMapper.toEntity(item).check(_clock.now());
    await _repository.update(checked);
    return ShoppingListItemMapper.toDto(checked);
  }
}

class UndoShoppingItemCheckUseCase {
  const UndoShoppingItemCheckUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item) =>
      _repository.update(ShoppingListItemMapper.toEntity(item).undoCheck());
}

class DeleteShoppingHistoryUseCase {
  const DeleteShoppingHistoryUseCase(this._repository);
  final ShoppingListRepository _repository;

  Future<void> execute(ShoppingListItemDto item) {
    if (item.purchasedAt == null) {
      throw const ApplicationValidationException('購入履歴の品物を指定してください');
    }
    return _repository.delete(ShoppingListItemMapper.toEntity(item));
  }
}
