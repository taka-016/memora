import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveGroupEventUsecaseProvider = Provider<SaveGroupEventUsecase>((ref) {
  return SaveGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});

class SaveGroupEventUsecase {
  final GroupEventRepository _groupEventRepository;

  SaveGroupEventUsecase(this._groupEventRepository);

  Future<GroupEventDto> execute(GroupEventDto groupEvent) async {
    final entity = GroupEventMapper.toEntity(groupEvent);
    final savedId = await _groupEventRepository.saveGroupEvent(entity);
    return groupEvent.copyWith(id: savedId);
  }
}
