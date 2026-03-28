import 'package:equatable/equatable.dart';

class GroupEventDto extends Equatable {
  const GroupEventDto({
    required this.id,
    required this.groupId,
    required this.year,
    required this.memo,
  });

  final String id;
  final String groupId;
  final int year;
  final String memo;

  GroupEventDto copyWith({
    String? id,
    String? groupId,
    int? year,
    String? memo,
  }) {
    return GroupEventDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, groupId, year, memo];
}
