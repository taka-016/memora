import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/repositories/firestore_write_context.dart';
import 'package:memora/infrastructure/services/firestore_deleted_parent_store.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirestoreWriteContext, CollectionReference, DocumentReference])
import 'firestore_deleted_parent_store_test.mocks.dart';

void main() {
  for (final isGroup in [true, false]) {
    final name = isGroup ? 'グループ' : 'メンバー';
    test('$nameの元のIDと全フィールドを退避先への書き込みに引き継ぐ', () {
      final context = MockFirestoreWriteContext();
      final collection = MockCollectionReference<Map<String, dynamic>>();
      final reference = MockDocumentReference<Map<String, dynamic>>();
      final collectionName = isGroup ? 'deleted_groups' : 'deleted_members';
      final timestamp = Timestamp.fromDate(DateTime.utc(2026, 10, 17));
      final data = <String, dynamic>{
        'ownerId': 'owner',
        if (isGroup) ...{'name': '家族', 'memo': null},
        if (!isGroup) ...{
          'accountId': 'account',
          'hiraganaFirstName': 'たろう',
          'hiraganaLastName': 'やまだ',
          'kanjiFirstName': '太郎',
          'kanjiLastName': '山田',
          'firstName': 'Taro',
          'lastName': 'Yamada',
          'displayName': '太郎',
          'type': '家族',
          'birthday': timestamp,
          'gender': null,
          'email': 'taro@example.com',
          'phoneNumber': '09012345678',
        },
        'version': 5,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'additionalField': {'value': ['保持する']},
      };
      when(context.collection(collectionName)).thenReturn(collection);
      when(collection.doc('original')).thenReturn(reference);
      final store = FirestoreDeletedParentStore(context);

      if (isGroup) {
        store.saveGroup('original', data);
      } else {
        store.saveMember('original', data);
      }

      verify(context.set(reference, data)).called(1);
      verifyNever(context.commit());
      verifyNever(context.delete(any));
    });
  }
}
