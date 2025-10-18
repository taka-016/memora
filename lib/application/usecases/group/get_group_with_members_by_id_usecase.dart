import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getGroupByIdUsecaseProvider = Provider<GetGroupWithMembersByIdUsecase>((
  ref,
) {
  return GetGroupWithMembersByIdUsecase(ref.watch(groupQueryServiceProvider));
});

class GetGroupWithMembersByIdUsecase {
  final GroupQueryService _groupQueryServiceProvider;

  GetGroupWithMembersByIdUsecase(this._groupQueryServiceProvider);

  Future<GroupDto?> execute(String id) async {
    return await _groupQueryServiceProvider.getGroupWithMembersById(id);
  }
}
