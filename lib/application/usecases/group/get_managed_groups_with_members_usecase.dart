import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getManagedGroupsWithMembersUsecaseProvider =
    Provider<GetManagedGroupsWithMembersUsecase>((ref) {
      return GetManagedGroupsWithMembersUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });

class GetManagedGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetManagedGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupDto>> execute(Member member) async {
    return await _groupQueryService.getManagedGroupsWithMembersByOwnerId(
      member.id,
      groupsOrderBy: [const OrderBy('name', descending: false)],
      membersOrderBy: [const OrderBy('displayName', descending: false)],
    );
  }
}
