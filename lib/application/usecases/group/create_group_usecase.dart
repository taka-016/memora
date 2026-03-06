import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createGroupUsecaseProvider = Provider<CreateGroupUsecase>((ref) {
  return CreateGroupUsecase(ref.watch(groupRepositoryProvider));
});

class CreateGroupUsecase {
  final GroupRepository _groupRepository;

  CreateGroupUsecase(this._groupRepository);

  Future<String> execute(GroupDto group) async {
    return await _groupRepository.saveGroup(GroupMapper.toEntity(group));
  }
}
