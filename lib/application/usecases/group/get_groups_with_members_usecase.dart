import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/application/interfaces/query_services/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getGroupsWithMembersUsecaseProvider =
    Provider<GetGroupsWithMembersUsecase>((ref) {
      return GetGroupsWithMembersUsecase(ref.watch(groupQueryServiceProvider));
    });

class GetGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupDto>> execute(Member member) async {
    return await _groupQueryService.getGroupsWithMembersByMemberId(
      member.id,
      groupsOrderBy: [const OrderBy('name', descending: false)],
      membersOrderBy: [const OrderBy('displayName', descending: false)],
    );
  }
}
