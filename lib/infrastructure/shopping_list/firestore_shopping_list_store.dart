import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/shopping_list_repository.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';
import 'package:memora/infrastructure/shopping_list/shopping_history_paging.dart';

class FirestoreShoppingListStore
    implements ShoppingListRepository, ShoppingListQueryService {
  FirestoreShoppingListStore(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('shopping_list_items');

  Map<String, Object?> _data(ShoppingListItem item) => {
    'groupId': item.groupId,
    'name': item.name,
    'quantity': item.quantity,
    'purchasedAt': item.purchasedAt == null
        ? null
        : Timestamp.fromDate(item.purchasedAt!),
    'version': item.version,
  };

  ShoppingListItemDto _dto(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ShoppingListItemDto(
      id: doc.id,
      groupId: data['groupId'] as String,
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      version: data['version'] as int,
    );
  }

  @override
  Future<void> add(ShoppingListItem item) =>
      _firestore.runTransaction((tx) async {
        final ref = _items.doc(item.id);
        FirestoreVersionCheck.requireAbsent((await tx.get(ref)).data());
        tx.set(ref, _data(item));
      });

  @override
  Future<void> update(ShoppingListItem item) =>
      _firestore.runTransaction((tx) async {
        final ref = _items.doc(item.id);
        final current = (await tx.get(ref)).data();
        FirestoreVersionCheck.requireMatch(current, item.version - 1);
        if (current!['groupId'] != item.groupId) {
          throw ValidationException('品物のグループは変更できません');
        }
        tx.update(ref, _data(item));
      });

  @override
  Future<void> delete(ShoppingListItem expected) =>
      _firestore.runTransaction((tx) async {
        final ref = _items.doc(expected.id);
        final current = (await tx.get(ref)).data();
        FirestoreVersionCheck.requireMatch(current, expected.version);
        if (current!['groupId'] != expected.groupId) {
          throw ValidationException('同じグループの品物を指定してください');
        }
        tx.delete(ref);
      });

  @override
  Stream<List<ShoppingListItemDto>> watchUnchecked(String groupId) => _items
      .where('groupId', isEqualTo: groupId)
      .where('purchasedAt', isNull: true)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map(
        (snapshot) => snapshot.docs.map(_dto).toList()
          ..sort((a, b) {
            final name = a.name.compareTo(b.name);
            return name == 0 ? a.id.compareTo(b.id) : name;
          }),
      );

  @override
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) => readShoppingHistoryPage(after, (last) async {
    var query = _items
        .where('groupId', isEqualTo: groupId)
        .where('purchasedAt', isNull: false)
        .orderBy('purchasedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(shoppingHistoryPageSize);
    if (last != null) {
      query = query.startAfter([
        Timestamp.fromDate(last.purchasedAt!),
        last.id,
      ]);
    }
    return (await query.get()).docs.map(_dto).toList();
  });
}
