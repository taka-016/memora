import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';
import 'package:memora/domain/entities/group/group_member.dart';

import 'firestore_group_member_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupMemberMapper', () {
    test('FirestoreのDocumentSnapshotからGroupMemberへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupmember001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'memberId': 'member001',
        'isAdministrator': true,
      });

      final groupMember = FirestoreGroupMemberMapper.fromFirestore(mockDoc);

      expect(groupMember.groupId, 'group001');
      expect(groupMember.memberId, 'member001');
      expect(groupMember.isAdministrator, true);
    });

    test('Firestoreのデータが不足している場合でもデフォルト値を返す', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('groupmember002');
      when(mockDoc.data()).thenReturn({});

      final groupMember = FirestoreGroupMemberMapper.fromFirestore(mockDoc);

      expect(groupMember.groupId, '');
      expect(groupMember.memberId, '');
      expect(groupMember.isAdministrator, false);
    });

    test('GroupMemberからFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: true,
      );

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], 'group001');
      expect(data['memberId'], 'member001');
      expect(data['isAdministrator'], true);
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('空文字を含むGroupMemberからFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(groupId: '', memberId: '');

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], '');
      expect(data['memberId'], '');
      expect(data['isAdministrator'], false);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
