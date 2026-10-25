import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.groupId,
    required this.memberId,
    this.isAdministrator = false,
    this.orderIndex = 0,
    this.color = '#2196F3',
    this.textColor,
  });

  final String groupId;
  final String color;
  final String? textColor;
  final String memberId;
  final bool isAdministrator;
  final int orderIndex;

  GroupMember copyWith({
    String? color,
    Object? textColor = _copyWithPlaceholder,
    String? groupId,
    String? memberId,
    bool? isAdministrator,
    int? orderIndex,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      color: color ?? this.color,
      textColor: identical(textColor, _copyWithPlaceholder)
          ? this.textColor
          : textColor as String?,
      memberId: memberId ?? this.memberId,
      isAdministrator: isAdministrator ?? this.isAdministrator,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [
    color,
    textColor,
    groupId,
    memberId,
    isAdministrator,
    orderIndex,
  ];
}

const Object _copyWithPlaceholder = Object();
