import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.groupId,
    required this.memberId,
    this.isAdministrator = false,
  });

  final String groupId;
  final String memberId;
  final bool isAdministrator;

  GroupMember copyWith({
    String? groupId,
    String? memberId,
    bool? isAdministrator,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      isAdministrator: isAdministrator ?? this.isAdministrator,
    );
  }

  @override
  List<Object?> get props => [groupId, memberId, isAdministrator];
}
