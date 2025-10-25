import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getMemberByIdUsecaseProvider = Provider<GetMemberByIdUseCase>((ref) {
  return GetMemberByIdUseCase(ref.watch(memberQueryServiceProvider));
});

class GetMemberByIdUseCase {
  final MemberQueryService _memberQueryService;

  GetMemberByIdUseCase(this._memberQueryService);

  Future<Member?> execute(String id) async {
    return await _memberQueryService.getMemberById(id);
  }
}
