import 'package:drift/drift.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/mappers/shopping_list_item_mapper.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/shopping_list_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';
import 'package:memora/infrastructure/shopping_list/shopping_history_paging.dart';

class SqliteShoppingListStore
    implements ShoppingListRepository, ShoppingListQueryService {
  SqliteShoppingListStore(this._database);

  final OfflineDatabase _database;
  static const _table = 'shopping_list_items';

  Map<String, Object?> _row(ShoppingListItem item) => {
    'id': item.id,
    'group_id': item.groupId,
    'name': item.name,
    'quantity': item.quantity,
    'is_listed': item.isListed ? 1 : 0,
    'purchased_at': item.purchasedAt?.microsecondsSinceEpoch,
    'version': item.version,
  };

  ShoppingListItemDto _dto(Map<String, Object?> row) => ShoppingListItemDto(
    id: row['id'] as String,
    groupId: row['group_id'] as String,
    name: row['name'] as String,
    quantity: row['quantity'] as String,
    isListed: row['is_listed'] == 1,
    purchasedAt: SqliteValues.date(row['purchased_at']),
    version: row['version'] as int,
  );

  @override
  Future<void> add(ShoppingListItem item) => _database.transaction(() async {
    final matches = await _database.rows(
      _table,
      where: 'group_id = ? AND name = ?',
      args: [item.groupId, item.name],
    );
    final row = matches.singleOrNull;
    if (row == null) {
      await _database.insertRow(_table, _row(item));
      return;
    }
    final existing = ShoppingListItemMapper.toEntity(_dto(row));
    await _database.updateRow(
      _table,
      existing.id,
      _row(existing.register(item.quantity)),
    );
  });

  @override
  Future<void> update(
    ShoppingListItem expected,
    ShoppingListItem replacement,
  ) => _database.transaction(() async {
    await _requireVersion(expected, expected.version);
    if (expected.name != replacement.name &&
        (await _database.rows(
          _table,
          where: 'group_id = ? AND name = ?',
          args: [expected.groupId, replacement.name],
        )).isNotEmpty) {
      throw ValidationException('同名の品物は登録済みです');
    }
    await _database.updateRow(_table, expected.id, _row(replacement));
  });

  @override
  Future<void> delete(ShoppingListItem expected) =>
      _database.transaction(() async {
        await _requireVersion(expected, expected.version);
        await _database.deleteRows(_table, 'id', expected.id);
      });

  Future<void> _requireVersion(ShoppingListItem item, int expected) async {
    final rows = await _database.rows(
      _table,
      where: 'id = ? AND group_id = ? AND version = ?',
      args: [item.id, item.groupId, expected],
    );
    if (rows.isEmpty) {
      throw ValidationException('品物が変更または削除されています。再読み込みしてください');
    }
  }

  @override
  Stream<List<ShoppingListItemDto>> watchUnchecked(String groupId) => _database
      .customSelect(
        'SELECT * FROM $_table WHERE group_id = ? AND is_listed = 1 '
        'ORDER BY name, id',
        variables: [Variable(groupId)],
        readsFrom: {_database.shoppingListItems},
      )
      .watch()
      .map((rows) => rows.map((row) => _dto(row.data)).toList());

  @override
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) async {
    final last = after?.lastItem;
    final date = last?.purchasedAt?.microsecondsSinceEpoch;
    final rows = await _database
        .customSelect(
          'SELECT * FROM $_table WHERE group_id = ? AND purchased_at IS NOT NULL '
          '${date == null ? '' : 'AND (purchased_at, id) < (?, ?) '}'
          'ORDER BY purchased_at DESC, id DESC LIMIT ?',
          variables: [
            Variable(groupId),
            if (date != null) ...[Variable(date), Variable(last!.id)],
            const Variable(shoppingHistoryPageSize + 1),
          ],
        )
        .get();
    return shoppingHistoryPage(rows.map((row) => _dto(row.data)).toList());
  }
}
