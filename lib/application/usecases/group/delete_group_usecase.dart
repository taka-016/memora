import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteGroupUsecaseProvider = Provider<DeleteGroupUsecase>((ref) {
  return DeleteGroupUsecase(
    ref.watch(groupRepositoryProvider),
    ref.watch(groupEventRepositoryProvider),
    ref.watch(tripEntryRepositoryProvider),
  );
});

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
