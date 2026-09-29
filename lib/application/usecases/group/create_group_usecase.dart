import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';

class CreateGroupUsecase {
  final GroupRepository _groupRepository;

  CreateGroupUsecase(this._groupRepository);

  Future<String> execute(GroupDto group) async {
    final entity = GroupMapper.toEntity(group);
    return await _groupRepository.saveGroup(entity);
  }
}
