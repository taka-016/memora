import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';

class GetMemberByIdUseCase {
  final MemberQueryService _memberQueryService;

  GetMemberByIdUseCase(this._memberQueryService);

  Future<MemberDto?> execute(String id) async {
    return await _memberQueryService.getMemberById(id);
  }
}
