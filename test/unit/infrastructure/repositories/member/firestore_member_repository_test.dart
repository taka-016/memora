import '../../../../helpers/firestore_transaction_store.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';
import 'package:memora/domain/entities/member/member.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
])
import 'firestore_member_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('members')).thenReturn(mockCollection);
      repository = FirestoreMemberRepository(firestore: mockFirestore);
    });

    test('本人登録ではメンバーと空の認可文書を同じバッチで作成する', () async {
      final store = FirestoreTransactionStore();
      final repository = FirestoreMemberRepository(firestore: store.firestore);
      await repository.saveMember(
        const Member(id: '', accountId: 'uid', displayName: '本人'),
      );
      final entry = store.rows.entries.singleWhere(
        (entry) => entry.key.startsWith('members/'),
      );
      expect(entry.value['groupIds'], isEmpty);
      expect(store.rows['account_permissions/uid'], {
        'memberId': entry.key.split('/').last,
        'memberGroupIds': <String>[],
        'managedGroupIds': <String>[],
      });
      expect(store.commits, 1);
    });

    test('未連携の管理メンバーには認可文書を作成しない', () async {
      final store = FirestoreTransactionStore();
      await FirestoreMemberRepository(firestore: store.firestore)
          .saveMember(const Member(id: '', ownerId: 'self', displayName: '家族'));
      expect(store.rows.length, 1);
      expect(store.rows.values.single['managedGroupIds'], isEmpty);
    });

    test('本人の退避と削除では認可文書も同じトランザクションで削除する', () async {
      final store = FirestoreTransactionStore();
      store.rows['members/m'] = {
        'version': 2,
        'accountId': 'uid',
        'groupIds': ['g'],
        'managedGroupIds': ['g'],
      };
      store.rows['account_permissions/uid'] = {
        'memberId': 'm',
        'memberGroupIds': ['g'],
        'managedGroupIds': ['g'],
      };
      await FirestoreMemberRepository(firestore: store.firestore)
          .deleteMember('m', expectedVersion: 2);
      expect(store.rows.containsKey('members/m'), false);
      expect(store.rows.containsKey('account_permissions/uid'), false);
      expect(store.rows['deleted_members/m']!['version'], 2);
      expect(store.commits, 1);
    });

    test('updateMemberがmembers collectionの該当ドキュメントを差分更新する', () async {
      final member = Member(
        id: 'member001',
        ownerId: 'admin001',
        displayName: '更新後表示名',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc('member001')).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      await repository.updateMember(member);

      verify(mockCollection.doc('member001')).called(1);
      verify(
        mockDocRef.update(
          argThat(
            allOf([
              containsPair('ownerId', 'admin001'),
              containsPair('displayName', '更新後表示名'),
              contains('updatedAt'),
              predicate<Map<String, dynamic>>(
                (data) => !data.containsKey('createdAt'),
                'createdAtを含まない',
              ),
            ]),
          ),
        ),
      ).called(1);
    });
  });
}
