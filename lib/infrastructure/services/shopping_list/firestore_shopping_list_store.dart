import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/services/shopping_list/shopping_list_store.dart';

class FirestoreShoppingListStore implements ShoppingListStore {
  const FirestoreShoppingListStore(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String groupId) => _firestore
      .collection('groups')
      .doc(groupId)
      .collection('shopping_list_items');

  @override
  Stream<List<ShoppingListItem>> watchPending(String groupId) =>
      _items(groupId)
          .where('isPending', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_toItem).toList());

  @override
  Future<List<ShoppingListItem>> purchases(
    String groupId, {
    required int limit,
    ShoppingListItem? after,
  }) async {
    var query = _purchaseHistory(groupId).limit(limit);
    if (after != null) {
      query = query.startAfter([
        after.purchasedAt!.microsecondsSinceEpoch,
        after.id,
      ]);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(_toItem).toList();
  }

  Query<Map<String, dynamic>> _purchaseHistory(String groupId) =>
      _items(groupId)
          .where('purchasedAt', isGreaterThan: 0)
          .orderBy('purchasedAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true);

  @override
  Future<T> write<T>(
    String groupId,
    Future<T> Function(ShoppingListWriteScope) action,
  ) => _firestore.runTransaction(
    (transaction) =>
        action(_FirestoreShoppingListWriteScope(_items(groupId), transaction)),
  );
}

ShoppingListItem _toItem(DocumentSnapshot<Map<String, dynamic>> snapshot) {
  final data = snapshot.data()!;
  return ShoppingListItem(
    id: snapshot.id,
    name: data['name'] as String,
    version: data['version'] as int,
    pendingQuantity: data['pendingQuantity'] as String?,
    purchasedAt: _date(data['purchasedAt'] as int?),
    purchasedQuantity: data['purchasedQuantity'] as String?,
  );
}

DateTime? _date(int? value) => value == null
    ? null
    : DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

class _FirestoreShoppingListWriteScope implements ShoppingListWriteScope {
  const _FirestoreShoppingListWriteScope(this._items, this._transaction);

  final CollectionReference<Map<String, dynamic>> _items;
  final Transaction _transaction;

  @override
  Future<ShoppingListItem?> read(String id) async {
    final snapshot = await _transaction.get(_items.doc(id));
    return snapshot.exists ? _toItem(snapshot) : null;
  }

  @override
  Future<void> delete(String id) async {
    _transaction.delete(_items.doc(id));
  }

  @override
  Future<void> save(ShoppingListItem item) async {
    _transaction.set(_items.doc(item.id), {
      'name': item.name,
      'version': item.version,
      'isPending': item.pendingQuantity != null,
      'pendingQuantity': item.pendingQuantity,
      'purchasedAt': item.purchasedAt?.microsecondsSinceEpoch,
      'purchasedQuantity': item.purchasedQuantity,
    });
  }
}
