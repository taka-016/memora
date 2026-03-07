import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';

import 'firestore_group_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreGroupMapper', () {
    test('FirestoreドキュメントからGroupDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('group001');
      when(
        doc.data(),
      ).thenReturn({'ownerId': 'owner001', 'name': '家族', 'memo': '毎年旅行'});
      const members = [
        GroupMemberDto(
          memberId: 'member001',
          groupId: 'group001',
          displayName: '山田太郎',
        ),
      ];

      final result = FirestoreGroupMapper.fromFirestore(doc, members: members);

      expect(result.id, 'group001');
      expect(result.ownerId, 'owner001');
      expect(result.name, '家族');
      expect(result.memo, '毎年旅行');
      expect(result.members, members);
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('group002');
      when(doc.data()).thenReturn({});

      final result = FirestoreGroupMapper.fromFirestore(doc);

      expect(result.id, 'group002');
      expect(result.ownerId, '');
      expect(result.name, '');
      expect(result.memo, isNull);
      expect(result.members, isEmpty);
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
  });
}
