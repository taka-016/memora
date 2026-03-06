import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreMemberInvitationMapper', () {
    test('FirestoreドキュメントからMemberInvitationDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'inv-1',
        data: {
          'inviteeId': 'invitee-1',
          'inviterId': 'inviter-1',
          'invitationCode': 'CODE1',
        },
      );

      final dto = FirestoreMemberInvitationMapper.fromFirestore(doc);

      expect(dto.id, 'inv-1');
      expect(dto.inviteeId, 'invitee-1');
      expect(dto.inviterId, 'inviter-1');
      expect(dto.invitationCode, 'CODE1');
    });

    test('Firestoreの欠損値は空文字で補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'inv-2', data: null);

      final dto = FirestoreMemberInvitationMapper.fromFirestore(doc);

      expect(dto.id, 'inv-2');
      expect(dto.inviteeId, '');
      expect(dto.inviterId, '');
      expect(dto.invitationCode, '');
    });

    test('MemberInvitationをFirestoreのMapへ変換できる', () {
      const invitation = MemberInvitation(
        id: 'inv-3',
        inviteeId: 'invitee-3',
        inviterId: 'inviter-3',
        invitationCode: 'CODE3',
      );

      final data = FirestoreMemberInvitationMapper.toFirestore(invitation);

      expect(data['inviteeId'], 'invitee-3');
      expect(data['inviterId'], 'inviter-3');
      expect(data['invitationCode'], 'CODE3');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
