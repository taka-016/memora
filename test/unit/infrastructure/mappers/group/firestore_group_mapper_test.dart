import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreGroupMapper', () {
    test('FirestoreドキュメントからGroupDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'group001',
        data: {'ownerId': 'owner001', 'name': 'テストグループ', 'memo': 'メモ'},
      );
      const members = [
        GroupMemberDto(
          memberId: 'member001',
          groupId: 'group001',
          displayName: '太郎',
        ),
      ];

      final dto = FirestoreGroupMapper.fromFirestore(doc, members: members);

      expect(dto.id, 'group001');
      expect(dto.ownerId, 'owner001');
      expect(dto.name, 'テストグループ');
      expect(dto.memo, 'メモ');
      expect(dto.members, hasLength(1));
    });

    test('Firestoreの欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'group002', data: {});

      final dto = FirestoreGroupMapper.fromFirestore(doc);

      expect(dto.id, 'group002');
      expect(dto.ownerId, '');
      expect(dto.name, '');
      expect(dto.members, isEmpty);
    });

    test('GroupをFirestoreのMapへ変換できる', () {
      final group = Group(
        id: 'group003',
        ownerId: 'owner003',
        name: '家族',
        memo: 'メモ',
      );

      final data = FirestoreGroupMapper.toFirestore(group);

      expect(data['ownerId'], 'owner003');
      expect(data['name'], '家族');
      expect(data['memo'], 'メモ');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
