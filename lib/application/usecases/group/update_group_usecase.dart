import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';

class UpdateGroupUsecase {
  final GroupRepository _groupRepository;

  UpdateGroupUsecase(this._groupRepository);

  Future<void> execute(GroupDto updatedGroup) async {
    final entity = GroupMapper.toEntity(updatedGroup);
    await _groupRepository.updateGroup(entity);
  }
}
