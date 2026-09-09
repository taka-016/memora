import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class GetManagedGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetManagedGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupDto>> execute(MemberDto member) async {
    return await _groupQueryService.getManagedGroupsWithMembersByOwnerId(
      member.id,
      groupsOrderBy: [const OrderBy('name', descending: false)],
      membersOrderBy: [const OrderBy('orderIndex', descending: false)],
    );
  }
}
