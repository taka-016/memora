import 'package:memora/domain/entities/member.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';

class GetManagedGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetManagedGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupWithMembersDto>> execute(Member member) async {
    return await _groupQueryService.getManagedGroupsWithMembersByOwnerId(
      member.id,
    );
  }
}
