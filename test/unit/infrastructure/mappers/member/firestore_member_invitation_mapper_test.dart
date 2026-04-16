import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';

import 'firestore_member_invitation_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreMemberInvitationMapper', () {
    test('FirestoreドキュメントからMemberInvitationDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('invitation001');
      when(doc.data()).thenReturn({
        'inviteeId': 'invitee001',
        'inviterId': 'inviter001',
        'invitationCode': 'code001',
      });

      final result = FirestoreMemberInvitationMapper.fromFirestore(doc);

      expect(result.id, 'invitation001');
      expect(result.inviteeId, 'invitee001');
      expect(result.inviterId, 'inviter001');
      expect(result.invitationCode, 'code001');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('invitation002');
      when(doc.data()).thenReturn({});

      final result = FirestoreMemberInvitationMapper.fromFirestore(doc);

      expect(result.id, 'invitation002');
      expect(result.inviteeId, '');
      expect(result.inviterId, '');
      expect(result.invitationCode, '');
    });

    test('MemberInvitationを新規作成用FirestoreのMapへ変換できる', () {
      const memberInvitation = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'code001',
      );

      final data = FirestoreMemberInvitationMapper.toCreateFirestore(
        memberInvitation,
      );

      expect(data['inviteeId'], 'invitee001');
      expect(data['inviterId'], 'inviter001');
      expect(data['invitationCode'], 'code001');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });

    test('空文字を含むMemberInvitationでも更新用FirestoreのMapへ変換できる', () {
      const memberInvitation = MemberInvitation(
        id: 'invitation003',
        inviteeId: '',
        inviterId: '',
        invitationCode: '',
      );

      final data = FirestoreMemberInvitationMapper.toUpdateFirestore(
        memberInvitation,
      );

      expect(data['inviteeId'], '');
      expect(data['inviterId'], '');
      expect(data['invitationCode'], '');
      expect(data.containsKey('createdAt'), isFalse);
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
