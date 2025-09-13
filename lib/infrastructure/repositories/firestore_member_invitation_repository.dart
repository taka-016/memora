import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/member_invitation.dart';
import '../../domain/repositories/member_invitation_repository.dart';
import '../mappers/firestore_member_invitation_mapper.dart';

class FirestoreMemberInvitationRepository
    implements MemberInvitationRepository {
  final FirebaseFirestore _firestore;

  FirestoreMemberInvitationRepository(this._firestore);

  @override
  Future<MemberInvitation?> getByInviteeId(String inviteeId) async {
    final querySnapshot = await _firestore
        .collection('member_invitations')
        .where('inviteeId', isEqualTo: inviteeId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return FirestoreMemberInvitationMapper.fromFirestore(
      querySnapshot.docs.first,
    );
  }

  @override
  Future<MemberInvitation?> getByInvitationCode(String invitationCode) async {
    final querySnapshot = await _firestore
        .collection('member_invitations')
        .where('invitationCode', isEqualTo: invitationCode)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return FirestoreMemberInvitationMapper.fromFirestore(
      querySnapshot.docs.first,
    );
  }

  @override
  Future<void> save(MemberInvitation memberInvitation) async {
    final data = FirestoreMemberInvitationMapper.toFirestore(memberInvitation);

    if (memberInvitation.id.isEmpty) {
      // 新規作成
      await _firestore.collection('member_invitations').add(data);
    } else {
      // 更新
      await _firestore
          .collection('member_invitations')
          .doc(memberInvitation.id)
          .set(data);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection('member_invitations').doc(id).delete();
  }
}
