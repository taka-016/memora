import 'package:equatable/equatable.dart';

class GroupEvent extends Equatable {
  const GroupEvent({
    required this.groupId,
    required this.type,
    this.name,
    required this.startDate,
    required this.endDate,
    this.memo,
  });

  final String groupId;
  final String type;
  final String? name;
  final DateTime startDate;
  final DateTime endDate;
  final String? memo;

  GroupEvent copyWith({
    String? groupId,
    String? type,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return GroupEvent(
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [groupId, type, name, startDate, endDate, memo];
}
