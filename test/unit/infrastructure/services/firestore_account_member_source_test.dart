import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/firestore_account_member_source.dart';

import '../queries/member/firestore_member_query_service_test.mocks.dart';

void main() {
  test('未ログインなら本人のメンバー情報を取得しない', () async {
    final db = MockFirebaseFirestore();
    final source = FirestoreAccountMemberSource(db, accountId: () => null);
    expect(await source.current(), isNull);
    verifyZeroInteractions(db);
  });
}
