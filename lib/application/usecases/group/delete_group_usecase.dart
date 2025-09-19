import '../../../domain/repositories/group_repository.dart';
import '../../../domain/repositories/group_event_repository.dart';
import '../../../domain/repositories/trip_entry_repository.dart';
import '../../../domain/repositories/pin_repository.dart';
import '../../../domain/repositories/trip_participant_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;
  final GroupEventRepository _groupEventRepository;
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;
  final TripParticipantRepository _tripParticipantRepository;

  DeleteGroupUsecase(
    this._groupRepository,
    this._groupEventRepository,
    this._tripEntryRepository,
    this._pinRepository,
    this._tripParticipantRepository,
  );

  Future<void> execute(String groupId) async {
    final tripEntries = await _tripEntryRepository.getTripEntries();
    final targetTripEntries = tripEntries.where(
      (entry) => entry.groupId == groupId,
    );
    await Future.wait([
      for (final entry in targetTripEntries) ...[
        _pinRepository.deletePinsByTripId(entry.id),
        _tripParticipantRepository.deleteTripParticipantsByTripId(entry.id),
      ],
    ]);
    await _tripEntryRepository.deleteTripEntriesByGroupId(groupId);
    await _groupEventRepository.deleteGroupEventsByGroupId(groupId);
    await _groupRepository.deleteGroup(groupId);
  }
}
