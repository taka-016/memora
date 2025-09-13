import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/infrastructure/mappers/firestore_member_invitation_mapper.dart';

import 'firestore_member_invitation_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreMemberInvitationMapper', () {
    test('FirestoreのDocumentSnapshotからMemberInvitationへ変換できる', () {
      // Arrange
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('invitation123');
      when(mockDoc.data()).thenReturn({
        'inviteeId': 'invitee123',
        'inviterId': 'inviter456',
        'invitationCode': 'code789',
      });

      // Act
      final memberInvitation = FirestoreMemberInvitationMapper.fromFirestore(
        mockDoc,
      );

      // Assert
      expect(memberInvitation.id, 'invitation123');
      expect(memberInvitation.inviteeId, 'invitee123');
      expect(memberInvitation.inviterId, 'inviter456');
      expect(memberInvitation.invitationCode, 'code789');
    });

    test('MemberInvitationからFirestoreのMapに変換できる', () {
      // Arrange
      const memberInvitation = MemberInvitation(
        id: 'invitation123',
        inviteeId: 'invitee123',
        inviterId: 'inviter456',
        invitationCode: 'code789',
      );

      // Act
      final map = FirestoreMemberInvitationMapper.toFirestore(memberInvitation);

      // Assert
      expect(map['inviteeId'], 'invitee123');
      expect(map['inviterId'], 'inviter456');
      expect(map['invitationCode'], 'code789');
      expect(map.containsKey('id'), false);
    });
  });
}
