import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreMemberInvitationMapper', () {
    test('MemberInvitationからFirestoreのMapへ変換できる', () {
      const memberInvitation = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'code001',
      );

      final data = FirestoreMemberInvitationMapper.toFirestore(
        memberInvitation,
      );

      expect(data['inviteeId'], 'invitee001');
      expect(data['inviterId'], 'inviter001');
      expect(data['invitationCode'], 'code001');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('空文字を含むMemberInvitationからFirestoreのMapへ変換できる', () {
      const memberInvitation = MemberInvitation(
        id: 'invitation003',
        inviteeId: '',
        inviterId: '',
        invitationCode: '',
      );

      final data = FirestoreMemberInvitationMapper.toFirestore(
        memberInvitation,
      );

      expect(data['inviteeId'], '');
      expect(data['inviterId'], '');
      expect(data['invitationCode'], '');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
