import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

class CreateGroupUsecase {
  final GroupRepository _groupRepository;

  CreateGroupUsecase(this._groupRepository);

  Future<String> execute(Group group) async {
    return await _groupRepository.saveGroup(group);
  }
}
