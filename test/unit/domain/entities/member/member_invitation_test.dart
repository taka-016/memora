import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';

void main() {
  group('MemberInvitation', () {
    test('インスタンス生成が正しく行われる', () {
      final memberInvitation = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );

      expect(memberInvitation.id, 'invitation001');
      expect(memberInvitation.inviteeId, 'invitee001');
      expect(memberInvitation.inviterId, 'inviter001');
      expect(
        memberInvitation.invitationCode,
        'abc12345-def6-789g-hijk-lmn012345678',
      );
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final invitation1 = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );
      final invitation2 = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );

      expect(invitation1, equals(invitation2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final invitation1 = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );
      final invitation2 = MemberInvitation(
        id: 'invitation002',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );

      expect(invitation1, isNot(equals(invitation2)));
    });

    test('copyWithメソッドが正しく動作する', () {
      final invitation = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );
      final updatedInvitation = invitation.copyWith(
        invitationCode: 'new-invitation-code-12345',
      );

      expect(updatedInvitation.id, 'invitation001');
      expect(updatedInvitation.inviteeId, 'invitee001');
      expect(updatedInvitation.inviterId, 'inviter001');
      expect(updatedInvitation.invitationCode, 'new-invitation-code-12345');
    });

    test('copyWithメソッドで変更しないフィールドは元の値が保持される', () {
      final invitation = MemberInvitation(
        id: 'invitation001',
        inviteeId: 'invitee001',
        inviterId: 'inviter001',
        invitationCode: 'abc12345-def6-789g-hijk-lmn012345678',
      );
      final updatedInvitation = invitation.copyWith(
        inviterId: 'new_inviter001',
      );

      expect(updatedInvitation.id, 'invitation001');
      expect(updatedInvitation.inviteeId, 'invitee001');
      expect(updatedInvitation.inviterId, 'new_inviter001');
      expect(
        updatedInvitation.invitationCode,
        'abc12345-def6-789g-hijk-lmn012345678',
      );
    });
  });
}
