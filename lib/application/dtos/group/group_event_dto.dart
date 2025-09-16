import 'package:equatable/equatable.dart';

class GroupEventDto extends Equatable {
  const GroupEventDto({
    this.id,
    required this.groupId,
    required this.type,
    this.name,
    required this.startDate,
    required this.endDate,
    this.memo,
  });

  final String? id;
  final String groupId;
  final String type;
  final String? name;
  final DateTime startDate;
  final DateTime endDate;
  final String? memo;

  GroupEventDto copyWith({
    String? id,
    String? groupId,
    String? type,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return GroupEventDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    type,
    name,
    startDate,
    endDate,
    memo,
  ];
}
