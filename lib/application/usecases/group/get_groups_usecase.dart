import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';

class GetGroupsUsecase {
  final GroupRepository groupRepository;

  GetGroupsUsecase({required this.groupRepository});

  Future<List<Group>> execute() async {
    return await groupRepository.getGroups();
  }
}
