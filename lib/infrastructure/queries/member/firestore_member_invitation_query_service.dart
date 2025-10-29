import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/core/app_logger.dart';

class FirestoreMemberInvitationQueryService
    implements MemberInvitationQueryService {
  final FirebaseFirestore _firestore;

  FirestoreMemberInvitationQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<MemberInvitationDto?> getByInviteeId(String inviteeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('member_invitations')
          .where('inviteeId', isEqualTo: inviteeId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return MemberInvitationMapper.fromFirestore(querySnapshot.docs.first);
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
  Future<MemberInvitationDto?> getByInvitationCode(
    String invitationCode,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('member_invitations')
          .where('invitationCode', isEqualTo: invitationCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return MemberInvitationMapper.fromFirestore(querySnapshot.docs.first);
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
