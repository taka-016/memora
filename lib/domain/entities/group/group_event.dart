import 'package:equatable/equatable.dart';

class GroupEvent extends Equatable {
  const GroupEvent({
    required this.id,
    required this.groupId,
    required this.year,
    required this.memo,
  });

  final String id;
  final String groupId;
  final int year;
  final String memo;

  GroupEvent copyWith({String? id, String? groupId, int? year, String? memo}) {
    return GroupEvent(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, groupId, year, memo];
}
