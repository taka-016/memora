import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';

class FirestoreMemberInvitationRepository
    implements MemberInvitationRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberInvitationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> acceptInvitation(
    Member member,
    List<MemberInvitation> invitations,
  ) async {
    final targets = List<MemberInvitation>.unmodifiable(invitations);
    final memberRef = _firestore.collection('members').doc(member.id);
    await _firestore.runTransaction<void>((transaction) async {
      final currentMember = await transaction.get(memberRef);
      FirestoreVersionCheck.requireMatch(currentMember.data(), member.version);
      for (final invitation in targets) {
        final current = await transaction.get(
          _firestore.collection('member_invitations').doc(invitation.id),
        );
        FirestoreVersionCheck.requireMatch(current.data(), invitation.version);
      }
      transaction.update(
        memberRef,
        FirestoreMemberMapper.toUpdateFirestore(member),
      );
      for (final invitation in targets) {
        transaction.delete(
          _firestore.collection('member_invitations').doc(invitation.id),
        );
      }
    });
  }

  @override
  Future<void> saveMemberInvitation(MemberInvitation memberInvitation) async {
    final data = FirestoreMemberInvitationMapper.toCreateFirestore(
      memberInvitation,
    );
    await _firestore.collection('member_invitations').add(data);
  }

  @override
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation) async {
    final data = FirestoreMemberInvitationMapper.toUpdateFirestore(
      memberInvitation,
    );
    await _firestore
        .collection('member_invitations')
        .doc(memberInvitation.id)
        .update(data);
  }

  @override
  Future<void> deleteMemberInvitation(String id, {int? expectedVersion}) async {
    await FirestoreVersionCheck.delete(
      _firestore,
      _firestore.collection('member_invitations').doc(id),
      expectedVersion,
    );
  }
}
