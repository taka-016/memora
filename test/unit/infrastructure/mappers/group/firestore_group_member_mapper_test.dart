import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';
import 'package:memora/domain/entities/group/group_member.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreGroupMemberMapper', () {
    test('GroupMemberからFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: true,
        orderIndex: 2,
      );

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], 'group001');
      expect(data['memberId'], 'member001');
      expect(data['isAdministrator'], true);
      expect(data['orderIndex'], 2);
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('空文字を含むGroupMemberからFirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(groupId: '', memberId: '');

      final data = FirestoreGroupMemberMapper.toFirestore(groupMember);

      expect(data['groupId'], '');
      expect(data['memberId'], '');
      expect(data['isAdministrator'], false);
      expect(data['orderIndex'], 0);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
