import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

class GetGroupByIdUsecase {
  final GroupRepository _groupRepository;

  GetGroupByIdUsecase(this._groupRepository);

  Future<Group?> execute(String id) async {
    return await _groupRepository.getGroupById(id);
  }
}
