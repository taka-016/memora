import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;
  final GroupEventRepository _groupEventRepository;
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;

  DeleteGroupUsecase(
    this._groupRepository,
    this._groupEventRepository,
    this._tripEntryRepository,
    this._pinRepository,
  );

  Future<void> execute(String groupId) async {
    final tripEntries = await _tripEntryRepository.getTripEntriesByGroupId(
      groupId,
    );
    await Future.wait([
      for (final entry in tripEntries) ...[
        _pinRepository.deletePinsByTripId(entry.id),
      ],
    ]);
    await _tripEntryRepository.deleteTripEntriesByGroupId(groupId);
    await _groupEventRepository.deleteGroupEventsByGroupId(groupId);
    await _groupRepository.deleteGroup(groupId);
  }
}
