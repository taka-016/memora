import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';

class CreateGroupUsecase {
  final GroupRepository _groupRepository;

  CreateGroupUsecase(this._groupRepository);

  Future<void> execute(Group group) async {
    await _groupRepository.saveGroup(group);
  }
}
