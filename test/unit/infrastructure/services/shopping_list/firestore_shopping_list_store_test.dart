import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/infrastructure/services/shopping_list/firestore_shopping_list_store.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_shopping_list_store_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<Transaction>(),
])
void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference items;
  late FirestoreShoppingListStore store;

  setUp(() {
    firestore = MockFirebaseFirestore();
    items = MockCollectionReference();
    when(firestore.collection('shopping_list_items')).thenReturn(items);
    store = FirestoreShoppingListStore(firestore);
  });

  test('トップレベルの買い物リストをグループIDと未チェック状態で絞り込む', () async {
    final group = MockQuery();
    final pending = MockQuery();
    final snapshot = MockQuerySnapshot();
    when(items.where('groupId', isEqualTo: '家族')).thenReturn(group);
    when(group.where('isPending', isEqualTo: true)).thenReturn(pending);
    when(pending.snapshots()).thenAnswer((_) => Stream.value(snapshot));
    when(snapshot.docs).thenReturn([]);

    expect(await store.watchPending('家族').first, isEmpty);
    verify(pending.snapshots()).called(1);
  });

  test('トップレベルのドキュメントへグループID付きで保存する', () async {
    final transaction = MockTransaction();
    final document = MockDocumentReference();
    when(items.doc('milk')).thenReturn(document);
    when(firestore.runTransaction<void>(any)).thenAnswer((invocation) async {
      final action =
          invocation.positionalArguments.single as TransactionHandler<void>;
      await action(transaction);
    });

    await store.write(
      '家族',
      (scope) => scope.save(
        const ShoppingListItem(
          id: 'milk',
          name: '牛乳',
          version: 1,
          pendingQuantity: '',
        ),
      ),
    );

    final saved =
        verify(transaction.set(document, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(saved['groupId'], '家族');
    expect(saved['name'], '牛乳');
  });
}
