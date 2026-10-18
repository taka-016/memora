import 'package:equatable/equatable.dart';

class GroupEventDto extends Equatable {
  const GroupEventDto({
    this.version,
    required this.id,
    required this.groupId,
    required this.year,
    required this.memo,
  });

  final int? version;
  final String id;
  final String groupId;
  final int year;
  final String memo;

  GroupEventDto copyWith({
    int? version,
    String? id,
    String? groupId,
    int? year,
    String? memo,
  }) {
    return GroupEventDto(
      version: version ?? this.version,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [version, id, groupId, year, memo];
}
