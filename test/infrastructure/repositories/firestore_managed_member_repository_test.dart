import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_managed_member_repository.dart';
import 'package:memora/domain/entities/managed_member.dart';
import 'firestore_group_member_repository_test.mocks.dart';

void main() {
  group('FirestoreManagedMemberRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreManagedMemberRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('managed_members')).thenReturn(mockCollection);
      repository = FirestoreManagedMemberRepository(firestore: mockFirestore);
    });

    test('saveManagedMemberがmanaged_members collectionに管理メンバー情報をaddする', () async {
      final managedMember = ManagedMember(
        id: 'managedmember001',
        memberId: 'member001',
        managedMemberId: 'member002',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveManagedMember(managedMember);

      verify(
        mockCollection.add(argThat(
          allOf([
            containsPair('memberId', 'member001'),
            containsPair('managedMemberId', 'member002'),
            containsPair('createdAt', isA<FieldValue>()),
          ])
        )),
      ).called(1);
    });

    test('getManagedMembersが管理メンバーのリストを返す', () async {
      when(mockDoc1.id).thenReturn('managedmember001');
      when(mockDoc1.data()).thenReturn({
        'memberId': 'member001',
        'managedMemberId': 'member002',
      });
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

      final result = await repository.getManagedMembers();

      expect(result.length, 1);
      expect(result[0].id, 'managedmember001');
      expect(result[0].memberId, 'member001');
      expect(result[0].managedMemberId, 'member002');
    });

    test('deleteManagedMemberが指定されたIDの管理メンバーを削除する', () async {
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      when(mockCollection.doc('managedmember001')).thenReturn(mockDoc);
      when(mockDoc.delete()).thenAnswer((_) async {});

      await repository.deleteManagedMember('managedmember001');

      verify(mockDoc.delete()).called(1);
    });

    test('getManagedMembersByMemberIdが指定されたmemberIdの管理メンバーを返す', () async {
      when(mockCollection.where('memberId', isEqualTo: 'member001')).thenReturn(mockQuery);
      when(mockDoc1.id).thenReturn('managedmember001');
      when(mockDoc1.data()).thenReturn({
        'memberId': 'member001',
        'managedMemberId': 'member002',
      });
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      final result = await repository.getManagedMembersByMemberId('member001');

      expect(result.length, 1);
      expect(result[0].memberId, 'member001');
      expect(result[0].managedMemberId, 'member002');
    });

    test('getManagedMembersByManagedMemberIdが指定されたmanagedMemberIdの管理メンバーを返す', () async {
      when(mockCollection.where('managedMemberId', isEqualTo: 'member002')).thenReturn(mockQuery);
      when(mockDoc1.id).thenReturn('managedmember001');
      when(mockDoc1.data()).thenReturn({
        'memberId': 'member001',
        'managedMemberId': 'member002',
      });
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      final result = await repository.getManagedMembersByManagedMemberId('member002');

      expect(result.length, 1);
      expect(result[0].memberId, 'member001');
      expect(result[0].managedMemberId, 'member002');
    });
  });
}