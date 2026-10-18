import 'package:equatable/equatable.dart';

class GroupEvent extends Equatable {
  const GroupEvent({
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

  GroupEvent copyWith({
    int? version,
    String? id,
    String? groupId,
    int? year,
    String? memo,
  }) {
    return GroupEvent(
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
