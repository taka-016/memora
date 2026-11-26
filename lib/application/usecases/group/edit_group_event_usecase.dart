import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';

class EditGroupEventUsecase {
  EditGroupEventUsecase(this._repository);

  final GroupEventRepository _repository;

  Future<GroupEventDto?> execute({
    required String groupId,
    required int year,
    required String memo,
    required GroupEventDto? eventAtOpen,
  }) async {
    if (memo.isEmpty) {
      if (eventAtOpen != null) {
        await _repository.deleteGroupEvent(
          eventAtOpen.id,
          expectedVersion: eventAtOpen.version,
        );
      }
      return null;
    }

    final event = GroupEventDto(
      id: eventAtOpen?.id ?? '',
      version: eventAtOpen?.version,
      groupId: groupId,
      year: year,
      memo: memo,
    );
    final id = await _repository.saveGroupEvent(
      GroupEventMapper.toEntity(event),
    );
    return event.copyWith(id: id);
  }
}
