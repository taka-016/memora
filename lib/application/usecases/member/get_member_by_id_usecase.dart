import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getMemberByIdUsecaseProvider = Provider<GetMemberByIdUseCase>((ref) {
  return GetMemberByIdUseCase(ref.watch(memberQueryServiceProvider));
});

class GetMemberByIdUseCase {
  final MemberQueryService _memberQueryService;

  GetMemberByIdUseCase(this._memberQueryService);

  Future<MemberDto?> execute(String id) async {
    return await _memberQueryService.getMemberById(id);
  }
}
