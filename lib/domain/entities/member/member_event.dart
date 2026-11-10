import 'package:equatable/equatable.dart';

class MemberEvent extends Equatable {
  const MemberEvent({
    this.version,
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.year,
    required this.memo,
  });

  final int? version;
  final String id;
  final String groupId;
  final String memberId;
  final int year;
  final String memo;

  MemberEvent copyWith({
    int? version,
    String? id,
    String? groupId,
    String? memberId,
    int? year,
    String? memo,
  }) {
    return MemberEvent(
      version: version ?? this.version,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [version, id, groupId, memberId, year, memo];
}
