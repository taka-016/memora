import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

enum GroupMemberSort { displayOrder }

class GetGroupWithMembersByIdUsecase {
  final GroupQueryService _groupQueryService;

  GetGroupWithMembersByIdUsecase(this._groupQueryService);

  Future<GroupDto?> execute(
    String groupId, {
    GroupMemberSort? membersSort,
  }) async {
    return await _groupQueryService.getGroupWithMembersById(
      groupId,
      membersOrderBy: switch (membersSort) {
        GroupMemberSort.displayOrder => [const OrderBy('orderIndex')],
        null => null,
      },
    );
  }
}
