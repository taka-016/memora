import 'package:drift/drift.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/services/shopping_list/shopping_list_store.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

class SqliteShoppingListStore implements ShoppingListStore {
  const SqliteShoppingListStore(this._db);

  final OfflineDatabase _db;

  @override
  Stream<List<ShoppingListItem>> watchPending(String groupId) =>
      (_db.select(_db.shoppingListItems)..where(
            (row) =>
                row.groupId.equals(groupId) & row.pendingQuantity.isNotNull(),
          ))
          .watch()
          .map((rows) => rows.map(_toItem).toList());

  @override
  Future<List<ShoppingListItem>> purchases(
    String groupId, {
    required int limit,
    ShoppingListItem? after,
  }) async {
    final query = _db.select(_db.shoppingListItems)
      ..where(
        (row) => row.groupId.equals(groupId) & row.purchasedAt.isNotNull(),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.purchasedAt),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit);
    if (after != null) {
      final time = after.purchasedAt!.microsecondsSinceEpoch;
      query.where(
        (row) =>
            row.purchasedAt.isSmallerThanValue(time) |
            (row.purchasedAt.equals(time) &
                row.id.isSmallerThanValue(after.id)),
      );
    }
    return (await query.get()).map(_toItem).toList();
  }

  @override
  Future<T> write<T>(
    String groupId,
    Future<T> Function(ShoppingListWriteScope) action,
  ) => _db.transaction(
    () => action(_SqliteShoppingListWriteScope(_db, groupId)),
  );
}

ShoppingListItem _toItem(SqliteShoppingListItemRow row) => ShoppingListItem(
  id: row.id,
  name: row.name,
  version: row.version,
  pendingQuantity: row.pendingQuantity,
  purchasedAt: _date(row.purchasedAt),
  purchasedQuantity: row.purchasedQuantity,
);

DateTime? _date(int? value) => value == null
    ? null
    : DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

class _SqliteShoppingListWriteScope implements ShoppingListWriteScope {
  const _SqliteShoppingListWriteScope(this._db, this.groupId);

  final OfflineDatabase _db;
  final String groupId;

  @override
  Future<ShoppingListItem?> read(String id) async {
    final row =
        await (_db.select(_db.shoppingListItems)
              ..where((row) => row.groupId.equals(groupId) & row.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _toItem(row);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.shoppingListItems,
    )..where((row) => row.groupId.equals(groupId) & row.id.equals(id))).go();
  }

  @override
  Future<void> save(ShoppingListItem item) async {
    await _db
        .into(_db.shoppingListItems)
        .insertOnConflictUpdate(
          SqliteShoppingListItemRow(
            id: item.id,
            groupId: groupId,
            name: item.name,
            version: item.version,
            pendingQuantity: item.pendingQuantity,
            purchasedAt: item.purchasedAt?.microsecondsSinceEpoch,
            purchasedQuantity: item.purchasedQuantity,
          ).toCompanion(false),
        );
  }
}
