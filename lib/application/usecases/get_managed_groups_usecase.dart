import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/group_repository.dart';

class GetManagedGroupsUsecase {
  final GroupRepository _groupRepository;

  GetManagedGroupsUsecase(this._groupRepository);

  Future<List<Group>> execute(Member administratorMember) async {
    return await _groupRepository.getGroupsByAdministratorId(
      administratorMember.id,
    );
  }
}
