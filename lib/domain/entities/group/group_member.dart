import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.groupId,
    required this.memberId,
    this.isAdministrator = false,
    this.orderIndex = 0,
  });

  final String groupId;
  final String memberId;
  final bool isAdministrator;
  final int orderIndex;

  GroupMember copyWith({
    String? groupId,
    String? memberId,
    bool? isAdministrator,
    int? orderIndex,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      isAdministrator: isAdministrator ?? this.isAdministrator,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [groupId, memberId, isAdministrator, orderIndex];
}
