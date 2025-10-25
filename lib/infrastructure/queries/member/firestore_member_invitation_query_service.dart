import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';

class FirestoreMemberInvitationQueryService
    implements MemberInvitationQueryService {
  final FirebaseFirestore _firestore;

  FirestoreMemberInvitationQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<MemberInvitation?> getByInviteeId(String inviteeId) async {
    try {
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
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberInvitationQueryService.getByInviteeId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<MemberInvitation?> getByInvitationCode(String invitationCode) async {
    try {
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
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberInvitationQueryService.getByInvitationCode: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}
