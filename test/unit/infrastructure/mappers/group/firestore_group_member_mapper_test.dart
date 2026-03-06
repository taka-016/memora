import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreGroupMemberMapper', () {
    test('FirestoreドキュメントからGroupMemberDtoへ変換できる', () {
      final groupMemberDoc = FakeDocumentSnapshot(
        docId: 'gm001',
        data: {'groupId': 'group001', 'isAdministrator': true, 'orderIndex': 2},
      );
      final memberDoc = FakeDocumentSnapshot(
        docId: 'member001',
        data: {'displayName': '山田太郎'},
      );

      final dto = FirestoreGroupMemberMapper.fromFirestore(
        groupMemberDoc,
        memberDoc,
      );

      expect(dto.groupId, 'group001');
      expect(dto.memberId, 'member001');
      expect(dto.isAdministrator, isTrue);
      expect(dto.orderIndex, 2);
      expect(dto.displayName, '山田太郎');
    });

    test('isAdministrator未指定時はfalseになる', () {
      final groupMemberDoc = FakeDocumentSnapshot(
        docId: 'gm002',
        data: {'groupId': 'group002'},
      );
      final memberDoc = FakeDocumentSnapshot(docId: 'member002', data: {});

      final dto = FirestoreGroupMemberMapper.fromFirestore(
        groupMemberDoc,
        memberDoc,
      );

      expect(dto.groupId, 'group002');
      expect(dto.isAdministrator, isFalse);
      expect(dto.orderIndex, 0);
      expect(dto.displayName, '');
    });

    test('GroupMemberをFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(
        groupId: 'group003',
        memberId: 'member003',
        isAdministrator: true,
        orderIndex: 1,
      );

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], 'group003');
      expect(data['memberId'], 'member003');
      expect(data['isAdministrator'], isTrue);
      expect(data['orderIndex'], 1);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
