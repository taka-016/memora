import 'package:equatable/equatable.dart';

class CalendarLabelDto extends Equatable {
  const CalendarLabelDto({
    required this.id,
    required this.groupId,
    required this.name,
    required this.color,
    this.textColor = '#FFFFFF',
  });

  final String id;
  final String groupId;
  final String name;
  final String color;
  final String textColor;

  CalendarLabelDto copyWith({
    String? id,
    String? groupId,
    String? name,
    String? color,
    String? textColor,
  }) {
    return CalendarLabelDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
    );
  }

  @override
  List<Object?> get props => [id, groupId, name, color, textColor];
}
