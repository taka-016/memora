import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';

import '../../../helpers/test_exception.dart';
import 'calendar/firestore_calendar_repository_test.mocks.dart';

void main() {
  for (final isGroup in [true, false]) {
    final table = isGroup ? 'groups' : 'members';
    test('$tableを同一トランザクションで元の内容のまま退避する', () async {
      final firestore = MockFirebaseFirestore();
      final transaction = MockTransaction();
      final source = MockDocumentReference();
      final target = MockDocumentReference();
      final collection = MockCollectionReference();
      final archive = MockCollectionReference();
      final doc = MockDocumentSnapshot();
      final data = {
        'name': '退避前',
        'ownerId': 'owner',
        'updatedAt': Timestamp(1, 0),
        'version': 3,
      };
      when(firestore.collection(table)).thenReturn(collection);
      when(firestore.collection('deleted_$table')).thenReturn(archive);
      when(collection.doc('id')).thenReturn(source);
      when(archive.doc('id')).thenReturn(target);
      when(transaction.get(source)).thenAnswer((_) async => doc);
      when(doc.data()).thenReturn(data);
      when(firestore.runTransaction<void>(any)).thenAnswer((invocation) async {
        final action =
            invocation.positionalArguments.single as TransactionHandler<void>;
        await action(transaction);
      });
      Future<void> remove() => isGroup
          ? FirestoreGroupRepository(firestore: firestore)
                .deleteGroup('id', expectedVersion: 3)
          : FirestoreMemberRepository(firestore: firestore)
                .deleteMember('id', expectedVersion: 3);
      await remove();
      verifyInOrder([
        transaction.get(source),
        transaction.set(target, data),
        transaction.delete(source),
      ]);
      verifyNever(firestore.batch());
      final failure = TestException('退避失敗');
      when(transaction.set(target, any)).thenThrow(failure);
      await expectLater(remove(), throwsA(same(failure)));
      verifyNever(transaction.delete(source));
    });
  }
}
