import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/services/current_member_resolver.dart';
import 'package:memora/application/services/current_user_service.dart';

class AuthenticatedCurrentMemberResolver implements CurrentMemberResolver {
  AuthenticatedCurrentMemberResolver(this._members, this._users);

  final MemberQueryService _members;
  final CurrentUserService _users;

  @override
  Future<MemberDto?> resolve() async {
    final user = await _users.getCurrentUser();
    if (user == null) return null;
    return _members.getMemberByAccountId(user.id);
  }
}
