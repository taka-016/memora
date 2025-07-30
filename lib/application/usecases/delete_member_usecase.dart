import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/trip_participant_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/repositories/member_event_repository.dart';

class DeleteMemberUsecase {
  final MemberRepository _memberRepository;
  final TripParticipantRepository _tripParticipantRepository;
  final GroupMemberRepository _groupMemberRepository;
  final MemberEventRepository _memberEventRepository;

  DeleteMemberUsecase(
    this._memberRepository,
    this._tripParticipantRepository,
    this._groupMemberRepository,
    this._memberEventRepository,
  );

  Future<void> execute(String memberId) async {
    await _tripParticipantRepository.deleteTripParticipantsByMemberId(memberId);
    await _groupMemberRepository.deleteGroupMembersByMemberId(memberId);
    await _memberEventRepository.deleteMemberEventsByMemberId(memberId);
    await _memberRepository.deleteMember(memberId);
  }
}
