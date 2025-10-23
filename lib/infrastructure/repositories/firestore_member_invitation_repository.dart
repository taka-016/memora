import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/infrastructure/mappers/firestore_member_invitation_mapper.dart';

class FirestoreMemberInvitationRepository
    implements MemberInvitationRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberInvitationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMemberInvitation(MemberInvitation memberInvitation) async {
    final data = FirestoreMemberInvitationMapper.toFirestore(memberInvitation);
    await _firestore.collection('member_invitations').add(data);
  }

  @override
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation) async {
    final data = FirestoreMemberInvitationMapper.toFirestore(memberInvitation);
    await _firestore
        .collection('member_invitations')
        .doc(memberInvitation.id)
        .update(data);
  }

  @override
  Future<void> deleteMemberInvitation(String id) async {
    await _firestore.collection('member_invitations').doc(id).delete();
  }
}
