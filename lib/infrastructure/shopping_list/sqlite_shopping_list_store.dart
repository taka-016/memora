import 'package:drift/drift.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
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
    'purchased_at': item.purchasedAt?.microsecondsSinceEpoch,
    'version': item.version,
  };

  ShoppingListItemDto _dto(QueryRow row) => ShoppingListItemDto(
    id: row.read<String>('id'),
    groupId: row.read<String>('group_id'),
    name: row.read<String>('name'),
    quantity: row.read<String>('quantity'),
    purchasedAt: SqliteValues.date(row.data['purchased_at']),
    version: row.read<int>('version'),
  );

  @override
  Future<void> add(ShoppingListItem item) =>
      _database.insertRow(_table, _row(item));

  @override
  Future<void> update(ShoppingListItem item) => _database.transaction(() async {
    await _requireVersion(item, item.version - 1);
    await _database.updateRow(_table, item.id, _row(item));
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
        'SELECT * FROM $_table WHERE group_id = ? AND purchased_at IS NULL '
        'ORDER BY name, id',
        variables: [Variable(groupId)],
        readsFrom: {_database.shoppingListItems},
      )
      .watch()
      .map((rows) => rows.map(_dto).toList());

  @override
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) => readShoppingHistoryPage(after, (last) async {
    final date = last?.purchasedAt?.microsecondsSinceEpoch;
    final rows = await _database
        .customSelect(
          'SELECT * FROM $_table WHERE group_id = ? AND purchased_at IS NOT NULL '
          '${date == null ? '' : 'AND (purchased_at, id) < (?, ?) '}'
          'ORDER BY purchased_at DESC, id DESC LIMIT ?',
          variables: [
            Variable(groupId),
            if (date != null) ...[Variable(date), Variable(last!.id)],
            const Variable(shoppingHistoryPageSize),
          ],
        )
        .get();
    return rows.map(_dto).toList();
  });
}
