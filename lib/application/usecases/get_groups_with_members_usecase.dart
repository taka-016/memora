import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/services/group_query_service.dart';
import 'package:memora/infrastructure/dtos/group_with_members_dto.dart';

class GetGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupWithMembersDto>> execute(Member member) async {
    return await _groupQueryService.getGroupsWithMembersByMemberId(member.id);
  }
}
