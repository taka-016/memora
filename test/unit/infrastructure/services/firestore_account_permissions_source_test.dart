import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';

import '../queries/member/firestore_member_query_service_test.mocks.dart';

void main() {
  test('認証中の本人の認可文書を単一取得し所属と管理対象を返す', () async {
    final db = MockFirebaseFirestore();
    final collection = MockCollectionReference<Map<String, dynamic>>();
    final ref = MockDocumentReference<Map<String, dynamic>>();
    final doc = MockDocumentSnapshot<Map<String, dynamic>>();
    when(db.collection('account_permissions')).thenReturn(collection);
    when(collection.doc('uid')).thenReturn(ref);
    when(ref.get()).thenAnswer((_) async => doc);
    when(doc.exists).thenReturn(true);
    when(doc.data()).thenReturn({
      'memberId': 'm',
      'memberGroupIds': ['g1', 'g2'],
      'managedGroupIds': ['g2'],
    });
    final source = FirestoreAccountPermissionsSource(db, accountId: () => 'uid');
    final result = await source.current();
    expect(result?.memberId, 'm');
    expect(result?.memberGroupIds, ['g1', 'g2']);
    expect(result?.managedGroupIds, ['g2']);
    verify(collection.doc('uid')).called(1);
    verifyNever(collection.get());
  });

  test('未ログインなら認可文書を取得しない', () async {
    final db = MockFirebaseFirestore();
    final source = FirestoreAccountPermissionsSource(db, accountId: () => null);
    expect(await source.current(), isNull);
    verifyZeroInteractions(db);
  });
}
