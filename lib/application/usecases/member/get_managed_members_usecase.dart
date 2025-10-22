import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/query_services/member_query_service.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getManagedMembersUsecaseProvider = Provider<GetManagedMembersUsecase>((
  ref,
) {
  return GetManagedMembersUsecase(ref.watch(memberQueryServiceProvider));
});

class GetManagedMembersUsecase {
  final MemberQueryService _memberQueryService;

  GetManagedMembersUsecase(this._memberQueryService);

  Future<List<Member>> execute(Member ownerMember) async {
    return await _memberQueryService.getMembersByOwnerId(
      ownerMember.id,
      orderBy: [const OrderBy('displayName', descending: false)],
    );
  }
}
