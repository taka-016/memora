import '../../domain/entities/group_with_members.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/group_repository.dart';

class GetManagedGroupsWithMembersUsecase {
  final GroupRepository _groupRepository;

  GetManagedGroupsWithMembersUsecase(this._groupRepository);

  Future<List<GroupWithMembers>> execute(Member administratorMember) async {
    return await _groupRepository.getManagedGroupsWithMembersByAdministratorId(
      administratorMember.id,
    );
  }
}
