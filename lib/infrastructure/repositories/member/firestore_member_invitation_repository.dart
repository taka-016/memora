import 'package:memora/domain/entities/member/member.dart';
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
        {
          'accountId': member.accountId,
          'version': member.version! + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      final data = currentMember.data()!;
      transaction.set(
        _firestore.collection('account_permissions').doc(member.accountId),
        {
          'memberId': member.id,
          'memberGroupIds': List<String>.from(data['groupIds'] as List),
          'managedGroupIds': List<String>.from(data['managedGroupIds'] as List),
        },
      );
      transaction.delete(
        _firestore.collection('member_invitation_claims').doc(member.accountId),
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
    final ref = _firestore
        .collection('member_invitations')
        .doc(memberInvitation.invitationCode);
    await _firestore.runTransaction<void>((tx) async {
      FirestoreVersionCheck.requireAbsent((await tx.get(ref)).data());
      tx.set(
        ref,
        FirestoreMemberInvitationMapper.toCreateFirestore(memberInvitation),
      );
    });
  }

  @override
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation) async {
    final old = _firestore
        .collection('member_invitations')
        .doc(memberInvitation.id);
    final replacement = _firestore
        .collection('member_invitations')
        .doc(memberInvitation.invitationCode);
    await _firestore.runTransaction<void>((tx) async {
      FirestoreVersionCheck.requireMatch(
        (await tx.get(old)).data(),
        memberInvitation.version,
      );
      FirestoreVersionCheck.requireAbsent((await tx.get(replacement)).data());
      tx.delete(old);
      tx.set(
        replacement,
        FirestoreMemberInvitationMapper.toCreateFirestore(memberInvitation),
      );
    });
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
