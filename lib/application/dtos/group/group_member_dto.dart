import 'package:equatable/equatable.dart';

class GroupMemberDto extends Equatable {
  const GroupMemberDto({
    this.id,
    required this.groupId,
    required this.memberId,
  });

  final String? id;
  final String groupId;
  final String memberId;

  GroupMemberDto copyWith({String? id, String? groupId, String? memberId}) {
    return GroupMemberDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
    );
  }

  @override
  List<Object?> get props => [id, groupId, memberId];
}
