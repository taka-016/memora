import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetManagedMembersUsecase {
  final MemberQueryService _memberQueryService;

  GetManagedMembersUsecase(this._memberQueryService);

  Future<List<MemberDto>> execute(MemberDto ownerMember) async {
    return await _memberQueryService.getMembersByOwnerId(
      ownerMember.id,
      orderBy: [const OrderBy('displayName', descending: false)],
    );
  }
}
