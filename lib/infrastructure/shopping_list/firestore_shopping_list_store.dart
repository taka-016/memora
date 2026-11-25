import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/mappers/shopping_list_item_mapper.dart';
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

  Future<String> _documentId(String groupId, String name) async {
    final bytes = utf8.encode(jsonEncode([groupId, name]));
    return base64Url.encode((await Sha256().hash(bytes)).bytes);
  }

  Future<DocumentReference<Map<String, dynamic>>> _reference(
    ShoppingListItem item,
  ) async => _items.doc(await _documentId(item.groupId, item.name));

  Map<String, Object?> _data(ShoppingListItem item) => {
    'id': item.id,
    'groupId': item.groupId,
    'name': item.name,
    'quantity': item.quantity,
    'isListed': item.isListed,
    'purchasedAt': item.purchasedAt == null
        ? null
        : Timestamp.fromDate(item.purchasedAt!),
    'version': item.version,
  };

  ShoppingListItemDto _dto(Map<String, dynamic> data) {
    return ShoppingListItemDto(
      id: data['id'] as String,
      groupId: data['groupId'] as String,
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      isListed: data['isListed'] as bool,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      version: data['version'] as int,
    );
  }

  @override
  Future<void> add(ShoppingListItem item) async {
    final ref = await _reference(item);
    await _firestore.runTransaction((tx) async {
      final current = (await tx.get(ref)).data();
      if (current == null) {
        tx.set(ref, _data(item));
        return;
      }
      final existing = ShoppingListItemMapper.toEntity(_dto(current));
      tx.update(ref, _data(existing.register(item.quantity)));
    });
  }

  @override
  Future<void> update(
    ShoppingListItem expected,
    ShoppingListItem replacement,
  ) async {
    final source = await _reference(expected);
    final destination = expected.name == replacement.name
        ? source
        : await _reference(replacement);
    await _firestore.runTransaction((tx) async {
      _requireMatch((await tx.get(source)).data(), expected);
      if (destination == source) {
        tx.update(source, _data(replacement));
      } else {
        if ((await tx.get(destination)).exists) {
          throw ValidationException('同名の品物は登録済みです');
        }
        tx.set(destination, _data(replacement));
        tx.delete(source);
      }
    });
  }

  @override
  Future<void> delete(ShoppingListItem expected) async {
    final ref = await _reference(expected);
    await _firestore.runTransaction((tx) async {
      _requireMatch((await tx.get(ref)).data(), expected);
      tx.delete(ref);
    });
  }

  void _requireMatch(Map<String, dynamic>? current, ShoppingListItem expected) {
    FirestoreVersionCheck.requireMatch(
      current?['id'] == expected.id ? current : null,
      expected.version,
    );
  }

  @override
  Stream<List<ShoppingListItemDto>> watchUnchecked(String groupId) => _items
      .where('groupId', isEqualTo: groupId)
      .where('isListed', isEqualTo: true)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => _dto(doc.data())).toList()..sort((a, b) {
              final name = a.name.compareTo(b.name);
              return name == 0 ? a.id.compareTo(b.id) : name;
            }),
      );

  @override
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) async {
    final last = after?.lastItem;
    var query = _items
        .where('groupId', isEqualTo: groupId)
        .where('purchasedAt', isNull: false)
        .orderBy('purchasedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(shoppingHistoryPageSize + 1);
    if (last != null) {
      query = query.startAfter([
        Timestamp.fromDate(last.purchasedAt!),
        await _documentId(last.groupId, last.name),
      ]);
    }
    final snapshot = await query.get();
    return shoppingHistoryPage(
      snapshot.docs.map((doc) => _dto(doc.data())).toList(),
    );
  }
}
