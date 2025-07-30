import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../domain/repositories/trip_entry_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;
  final GroupMemberRepository _groupMemberRepository;
  final GroupEventRepository _groupEventRepository;
  final TripEntryRepository _tripEntryRepository;

  DeleteGroupUsecase(
    this._groupRepository,
    this._groupMemberRepository,
    this._groupEventRepository,
    this._tripEntryRepository,
  );

  Future<void> execute(String groupId) async {
    await _groupMemberRepository.deleteGroupMembersByGroupId(groupId);
    await _groupEventRepository.deleteGroupEventsByGroupId(groupId);
    await _tripEntryRepository.deleteTripEntriesByGroupId(groupId);
    await _groupRepository.deleteGroup(groupId);
  }
}
