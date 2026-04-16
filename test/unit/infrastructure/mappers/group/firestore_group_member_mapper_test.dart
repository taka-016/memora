import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';
import 'package:memora/domain/entities/group/group_member.dart';

import 'firestore_group_member_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreGroupMemberMapper', () {
    test('groupMemberDocとmemberDocからGroupMemberDtoへ変換できる', () {
      final groupMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(groupMemberDoc.data()).thenReturn({
        'groupId': 'group001',
        'isAdministrator': true,
        'orderIndex': 2.9,
      });

      final memberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(memberDoc.id).thenReturn('member001');
      when(memberDoc.data()).thenReturn({
        'displayName': '山田太郎',
        'birthday': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'email': 'taro@example.com',
      });

      final result = FirestoreGroupMemberMapper.fromFirestore(
        groupMemberDoc,
        memberDoc,
      );

      expect(result.memberId, 'member001');
      expect(result.groupId, 'group001');
      expect(result.isAdministrator, true);
      expect(result.orderIndex, 2);
      expect(result.displayName, '山田太郎');
      expect(result.birthday, DateTime(2000, 1, 1));
      expect(result.email, 'taro@example.com');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final groupMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(groupMemberDoc.data()).thenReturn({});

      final memberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(memberDoc.id).thenReturn('member002');
      when(memberDoc.data()).thenReturn({});

      final result = FirestoreGroupMemberMapper.fromFirestore(
        groupMemberDoc,
        memberDoc,
      );

      expect(result.memberId, 'member002');
      expect(result.groupId, '');
      expect(result.isAdministrator, false);
      expect(result.orderIndex, 0);
      expect(result.displayName, '');
      expect(result.birthday, isNull);
      expect(result.email, isNull);
    });

    test('GroupMemberを新規作成用FirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: true,
        orderIndex: 2,
      );

      final data = FirestoreGroupMemberMapper.toCreateFirestore(groupMember);

      expect(data['groupId'], 'group001');
      expect(data['memberId'], 'member001');
      expect(data['isAdministrator'], true);
      expect(data['orderIndex'], 2);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('空文字を含むGroupMemberでも新規作成用FirestoreのMapへ変換できる', () {
      final groupMember = GroupMember(groupId: '', memberId: '');

      final data = FirestoreGroupMemberMapper.toCreateFirestore(groupMember);

      expect(data['groupId'], '');
      expect(data['memberId'], '');
      expect(data['isAdministrator'], false);
      expect(data['orderIndex'], 0);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
