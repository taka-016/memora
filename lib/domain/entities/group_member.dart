import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.memberId,
  });

  final String id;
  final String groupId;
  final String memberId;

  GroupMember copyWith({String? id, String? groupId, String? memberId}) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
    );
  }

  @override
  List<Object?> get props => [id, groupId, memberId];
}
