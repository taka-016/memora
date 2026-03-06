import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateGroupUsecaseProvider = Provider<UpdateGroupUsecase>((ref) {
  return UpdateGroupUsecase(ref.watch(groupRepositoryProvider));
});

class UpdateGroupUsecase {
  final GroupRepository _groupRepository;

  UpdateGroupUsecase(this._groupRepository);

  Future<void> execute(GroupDto updatedGroup) async {
    await _groupRepository.updateGroup(GroupMapper.toEntity(updatedGroup));
  }
}
