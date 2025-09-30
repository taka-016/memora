import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/infrastructure/mappers/firestore_group_mapper.dart';
import 'package:memora/domain/entities/group.dart';

import 'firestore_group_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupMapper', () {
    test('FirestoreのDocumentSnapshotからGroupへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group001');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'admin001', 'name': 'テストグループ', 'memo': 'テストメモ'});

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.id, 'group001');
      expect(group.ownerId, 'admin001');
      expect(group.name, 'テストグループ');
      expect(group.memo, 'テストメモ');
      expect(group.members, isEmpty);
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group002');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'admin002', 'name': 'テストグループ2'});

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.id, 'group002');
      expect(group.ownerId, 'admin002');
      expect(group.name, 'テストグループ2');
      expect(group.memo, null);
      expect(group.members, isEmpty);
    });

    test('Firestoreのデータがnullの場合はデフォルト値に変換される', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group003');
      when(mockDoc.data()).thenReturn({});

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.id, 'group003');
      expect(group.ownerId, '');
      expect(group.name, '');
      expect(group.memo, isNull);
      expect(group.members, isEmpty);
    });

    test('GroupからFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], 'admin001');
      expect(data['name'], 'テストグループ');
      expect(data['memo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group002',
        ownerId: 'admin002',
        name: 'テストグループ2',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], 'admin002');
      expect(data['name'], 'テストグループ2');
      expect(data['memo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('空文字を含むGroupからFirestoreのMapへ変換できる', () {
      final group = Group(id: 'group004', ownerId: '', name: '');

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], '');
      expect(data['name'], '');
      expect(data['memo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('membersパラメータを指定した場合にGroupにメンバーが含まれる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group005');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'admin005', 'name': 'メンバー付きグループ', 'memo': 'メモ'});

      final members = [
        const GroupMember(
          groupId: 'group005',
          memberId: 'member001',
          isAdministrator: true,
        ),
        const GroupMember(
          groupId: 'group005',
          memberId: 'member002',
          isAdministrator: false,
        ),
      ];

      final group = FirestoreGroupMapper.fromFirestore(
        mockDoc,
        members: members,
      );

      expect(group.members, hasLength(2));
      expect(group.members[0].memberId, 'member001');
      expect(group.members[0].isAdministrator, true);
      expect(group.members[1].memberId, 'member002');
      expect(group.members[1].isAdministrator, false);
    });

    test('membersパラメータを指定しない場合は空のリストになる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group006');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'admin006', 'name': 'メンバー無しグループ'});

      final group = FirestoreGroupMapper.fromFirestore(mockDoc);

      expect(group.members, isEmpty);
    });
  });
}
