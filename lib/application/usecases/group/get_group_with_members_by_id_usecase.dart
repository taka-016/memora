import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getGroupWithMembersByIdUsecaseProvider =
    Provider<GetGroupWithMembersByIdUsecase>((ref) {
      return GetGroupWithMembersByIdUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });

class GetGroupWithMembersByIdUsecase {
  final GroupQueryService _groupQueryService;

  GetGroupWithMembersByIdUsecase(this._groupQueryService);

  Future<GroupDto?> execute(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async {
    return await _groupQueryService.getGroupWithMembersById(
      groupId,
      membersOrderBy: membersOrderBy,
    );
  }
}
