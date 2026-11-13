import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_member_query_service_test.mocks.dart';

@GenerateMocks([
  FirestoreAccountPermissionsSource,
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  group('FirestoreMemberQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockMembersCollection;
    late FirestoreMemberQueryService service;
    late MockFirestoreAccountPermissionsSource permissions;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockMembersCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('members'))
          .thenReturn(mockMembersCollection);
      permissions = MockFirestoreAccountPermissionsSource();
      when(permissions.forAccount(any)).thenAnswer((call) => FirestoreAccountPermissionsSource(mockFirestore).forAccount(call.positionalArguments.single as String));
      when(permissions.current()).thenAnswer((_) async => FirestoreAccountPermissions({'memberId': 'self', 'memberGroupIds': <String>[], 'managedGroupIds': <String>[]}));
      service = FirestoreMemberQueryService(firestore: mockFirestore, permissions: permissions);
    });

    test('メンバー一覧を取得しorderByを適用する', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockMembersCollection.where('ownerId', isEqualTo: 'self')).thenReturn(mockQuery);
      when(mockQuery.orderBy('displayName', descending: false))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member001');
      when(mockDoc.data()).thenReturn({'displayName': '山田太郎'});

      final result = await service.getMembers(
        orderBy: const [OrderBy('displayName', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first.displayName, '山田太郎');
      verify(mockMembersCollection.where('ownerId', isEqualTo: 'self')).called(1);
      verify(mockQuery.orderBy('displayName', descending: false))
          .called(1);
    });

    test('メンバー一覧取得で例外が発生した場合は取得失敗を伝える', () async {
      when(mockMembersCollection.where('ownerId', isEqualTo: 'self'))
          .thenThrow(TestException('Firestore error'));

      await expectLater(service.getMembers(), throwsA(isA<TestException>()));
    });

    test('メンバーIDでメンバーを取得する', () async {
      const memberId = 'member123';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockMembersCollection.doc(memberId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(memberId);
      when(mockDocSnapshot.data()).thenReturn({'displayName': '鈴木花子'});

      final result = await service.getMemberById(memberId);

      expect(result, isNotNull);
      expect(result, isA<MemberDto>());
      expect(result!.displayName, '鈴木花子');
    });

    test('メンバーIDで取得時に存在しない場合はnullを返す', () async {
      const memberId = 'member404';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockMembersCollection.doc(memberId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await service.getMemberById(memberId);

      expect(result, isNull);
    });

    test('メンバーIDで取得時に例外が発生した場合は取得失敗を伝える', () async {
      when(mockMembersCollection.doc(any))
          .thenThrow(TestException('Firestore error'));

      await expectLater(
        service.getMemberById('member001'),
        throwsA(isA<TestException>()),
      );
    });

    test('本人を認可文書の対応から取得する', () async {
      final permissions = MockCollectionReference<Map<String, dynamic>>();
      final permissionRef = MockDocumentReference<Map<String, dynamic>>();
      final permission = MockDocumentSnapshot<Map<String, dynamic>>();
      final memberRef = MockDocumentReference<Map<String, dynamic>>();
      final member = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('account_permissions'))
          .thenReturn(permissions);
      when(permissions.doc('account001')).thenReturn(permissionRef);
      when(permissionRef.get()).thenAnswer((_) async => permission);
      when(permission.exists).thenReturn(true);
      when(permission.data()).thenReturn({
        'memberId': 'member001',
        'memberGroupIds': <String>[],
        'managedGroupIds': <String>[],
      });
      when(mockMembersCollection.doc('member001')).thenReturn(memberRef);
      when(memberRef.get()).thenAnswer((_) async => member);
      when(member.exists).thenReturn(true);
      when(member.id).thenReturn('member001');
      when(member.data()).thenReturn({'displayName': '田中一郎'});
      expect(
        (await service.getMemberByAccountId('account001'))?.displayName,
        '田中一郎',
      );
      verifyNever(
        mockMembersCollection.where(
          'accountId',
          isEqualTo: anyNamed('isEqualTo'),
        ),
      );
    });

    test('認可文書がなければ未登録として扱う', () async {
      final permissions = MockCollectionReference<Map<String, dynamic>>();
      final ref = MockDocumentReference<Map<String, dynamic>>();
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('account_permissions'))
          .thenReturn(permissions);
      when(permissions.doc('missing')).thenReturn(ref);
      when(ref.get()).thenAnswer((_) async => doc);
      when(doc.exists).thenReturn(false);
      when(permissions.forAccount('missing')).thenAnswer((_) => FirestoreAccountPermissionsSource(mockFirestore).forAccount('missing'));
      expect(await service.getMemberByAccountId('missing'), isNull);
    });

    test('オーナーIDでメンバー一覧を取得する', () async {
      const ownerId = 'owner001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockMembersCollection.where('ownerId', isEqualTo: ownerId))
          .thenReturn(mockQuery);
      when(mockQuery.orderBy('displayName', descending: true))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member010');
      when(mockDoc.data()).thenReturn({'displayName': '佐藤次郎'});

      final result = await service.getMembersByOwnerId(
        ownerId,
        orderBy: const [OrderBy('displayName', descending: true)],
      );

      expect(result, hasLength(1));
      expect(result.first.displayName, '佐藤次郎');
      verify(mockQuery.orderBy('displayName', descending: true)).called(1);
    });

    test('オーナーIDでの取得時に例外が発生した場合は取得失敗を伝える', () async {
      when(
        mockMembersCollection.where(
          'ownerId',
          isEqualTo: anyNamed('isEqualTo'),
        ),
      ).thenThrow(TestException('Firestore error'));

      await expectLater(
        service.getMembersByOwnerId('owner001'),
        throwsA(isA<TestException>()),
      );
    });
  });
}
