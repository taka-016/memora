import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarLabel extends Equatable {
  CalendarLabel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.color,
  }) {
    if (groupId.trim().isEmpty) {
      throw ValidationException('グループは必須です');
    }
    if (name.trim().isEmpty) {
      throw ValidationException('色ラベルの名前は必須です');
    }
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
      throw ValidationException('色は#RRGGBB形式で指定してください');
    }
  }

  final String id;
  final String groupId;
  final String name;
  final String color;

  CalendarLabel copyWith({
    String? id,
    String? groupId,
    String? name,
    String? color,
  }) {
    return CalendarLabel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  List<Object?> get props => [id, groupId, name, color];
}
