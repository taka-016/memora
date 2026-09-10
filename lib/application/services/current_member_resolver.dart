import 'package:memora/application/dtos/member/member_dto.dart';

abstract class CurrentMemberResolver {
  Future<MemberDto?> resolve();
}
