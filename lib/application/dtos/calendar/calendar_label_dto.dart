import 'package:equatable/equatable.dart';

class CalendarLabelDto extends Equatable {
  const CalendarLabelDto({
    required this.id,
    required this.groupId,
    required this.name,
    required this.color,
    this.textColor = '#FFFFFF',
    this.sortOrder = 0,
  });

  final String id;
  final String groupId;
  final String name;
  final String color;
  final String textColor;
  final int sortOrder;

  CalendarLabelDto copyWith({
    String? id,
    String? groupId,
    String? name,
    String? color,
    String? textColor,
    int? sortOrder,
  }) {
    return CalendarLabelDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, groupId, name, color, textColor, sortOrder];
}

int compareCalendarLabels(CalendarLabelDto a, CalendarLabelDto b) {
  final order = a.sortOrder.compareTo(b.sortOrder);
  if (order != 0) return order;
  final name = a.name.compareTo(b.name);
  return name != 0 ? name : a.id.compareTo(b.id);
}
