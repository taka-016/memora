import 'package:equatable/equatable.dart';

class CalendarLabelDto extends Equatable {
  const CalendarLabelDto({
    required this.id,
    required this.groupId,
    required this.name,
    required this.color,
  });

  final String id;
  final String groupId;
  final String name;
  final String color;

  CalendarLabelDto copyWith({
    String? id,
    String? groupId,
    String? name,
    String? color,
  }) {
    return CalendarLabelDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [id, groupId, name, color];
}
