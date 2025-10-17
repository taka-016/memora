import 'package:memora/application/dtos/member/member_dto.dart';

class GroupWithMembersDto {
  final String id;
  final String name;
  final String? nemo;
  final List<MemberDto> members;

  GroupWithMembersDto({
    required this.id,
    required this.name,
    this.nemo,
    required this.members,
  });
}
