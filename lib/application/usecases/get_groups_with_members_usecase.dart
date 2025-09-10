import 'package:memora/domain/entities/member.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group_with_members_dto.dart';

class GetGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupWithMembersDto>> execute(Member member) async {
    return await _groupQueryService.getGroupsWithMembersByMemberId(member.id);
  }
}
