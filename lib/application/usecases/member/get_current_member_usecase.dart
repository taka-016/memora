import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/services/current_member_resolver.dart';

class GetCurrentMemberUseCase {
  GetCurrentMemberUseCase(this._resolver);

  final CurrentMemberResolver _resolver;

  Future<MemberDto?> execute() => _resolver.resolve();
}
