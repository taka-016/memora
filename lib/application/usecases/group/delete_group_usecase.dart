import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;
  final GroupEventRepository _groupEventRepository;
  final TripEntryRepository _tripEntryRepository;

  DeleteGroupUsecase(
    this._groupRepository,
    this._groupEventRepository,
    this._tripEntryRepository,
  );

  Future<void> execute(String groupId) async {
    await _tripEntryRepository.deleteTripEntriesByGroupId(groupId);
    await _groupEventRepository.deleteGroupEventsByGroupId(groupId);
    await _groupRepository.deleteGroup(groupId);
  }
}
