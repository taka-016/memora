import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/services/group_query_service.dart';
import 'package:memora/infrastructure/dtos/group_with_members_dto.dart';

class GetManagedGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetManagedGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupWithMembersDto>> execute(Member member) async {
    return await _groupQueryService
        .getManagedGroupsWithMembersByAdministratorId(member.id);
  }
}
