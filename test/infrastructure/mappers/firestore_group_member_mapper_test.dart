import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_group_member_mapper.dart';
import 'package:memora/domain/entities/group_member.dart';
import '../repositories/firestore_group_member_repository_test.mocks.dart';

void main() {
  group('FirestoreGroupMemberMapper', () {
    test('FirestoreのDocumentSnapshotからGroupMemberへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupmember001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'memberId': 'member001',
      });

      final groupMember = FirestoreGroupMemberMapper.fromFirestore(mockDoc);

      expect(groupMember.id, 'groupmember001');
      expect(groupMember.groupId, 'group001');
      expect(groupMember.memberId, 'member001');
    });

    test('GroupMemberからFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(
        id: 'groupmember001',
        groupId: 'group001',
        memberId: 'member001',
      );

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], 'group001');
      expect(data['memberId'], 'member001');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}