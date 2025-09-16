import 'package:equatable/equatable.dart';

class GroupMemberDto extends Equatable {
  const GroupMemberDto({required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  GroupMemberDto copyWith({String? groupId, String? memberId}) {
    return GroupMemberDto(
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
    );
  }

  @override
  List<Object> get props => [groupId, memberId];
}
