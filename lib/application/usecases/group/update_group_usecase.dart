import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

class UpdateGroupUsecase {
  final GroupRepository _groupRepository;

  UpdateGroupUsecase(this._groupRepository);

  Future<void> execute(Group updatedGroup) async {
    await _groupRepository.updateGroup(updatedGroup);
  }
}
