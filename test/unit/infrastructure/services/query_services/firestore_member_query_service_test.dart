import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/services/query_services/firestore_member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_member_query_service_test.mocks.dart';

@GenerateMocks([
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

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockMembersCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);
      service = FirestoreMemberQueryService(firestore: mockFirestore);
    });

    test('メンバー一覧を取得しorderByを適用する', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockMembersCollection.orderBy('displayName', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member001');
      when(mockDoc.data()).thenReturn({'displayName': '山田太郎'});

      final result = await service.getMembers(
        orderBy: const [OrderBy('displayName', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first.displayName, '山田太郎');
      verify(
        mockMembersCollection.orderBy('displayName', descending: false),
      ).called(1);
    });

    test('メンバー一覧取得で例外が発生した場合は空リストを返す', () async {
      when(
        mockMembersCollection.get(),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getMembers();

      expect(result, isEmpty);
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
      expect(result, isA<Member>());
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

    test('メンバーIDで取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockMembersCollection.doc(any),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getMemberById('member001');

      expect(result, isNull);
    });

    test('アカウントIDでメンバーを取得する', () async {
      const accountId = 'account001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockMembersCollection.where('accountId', isEqualTo: accountId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member001');
      when(mockDoc.data()).thenReturn({'displayName': '田中一郎'});

      final result = await service.getMemberByAccountId(accountId);

      expect(result, isNotNull);
      expect(result!.displayName, '田中一郎');
    });

    test('アカウントIDで取得時に該当しない場合はnullを返す', () async {
      const accountId = 'account404';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockMembersCollection.where('accountId', isEqualTo: accountId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final result = await service.getMemberByAccountId(accountId);

      expect(result, isNull);
    });

    test('アカウントIDで取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockMembersCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getMemberByAccountId('account001');

      expect(result, isNull);
    });

    test('オーナーIDでメンバー一覧を取得する', () async {
      const ownerId = 'owner001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockMembersCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('displayName', descending: true),
      ).thenReturn(mockQuery);
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

    test('オーナーIDでの取得時に例外が発生した場合は空リストを返す', () async {
      when(
        mockMembersCollection.where(
          'ownerId',
          isEqualTo: anyNamed('isEqualTo'),
        ),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getMembersByOwnerId('owner001');

      expect(result, isEmpty);
    });
  });
}
