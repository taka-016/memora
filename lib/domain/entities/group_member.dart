import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  GroupMember copyWith({String? id, String? groupId, String? memberId}) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
    );
  }

  @override
  List<Object?> get props => [groupId, memberId];
}
