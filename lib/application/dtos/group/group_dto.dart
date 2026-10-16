import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

class GroupDto extends Equatable {
  const GroupDto({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    required this.members,
    this.originalMembers,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  final List<GroupMemberDto> members;
  final List<GroupMemberDto>? originalMembers;

  GroupDto copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? memo,
    List<GroupMemberDto>? members,
    List<GroupMemberDto>? originalMembers,
  }) {
    return GroupDto(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      members: members ?? this.members,
      originalMembers: originalMembers ?? this.originalMembers ?? this.members,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, memo, members, originalMembers];
}
