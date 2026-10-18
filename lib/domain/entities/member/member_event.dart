import 'package:equatable/equatable.dart';

class MemberEvent extends Equatable {
  const MemberEvent({
    this.version,
    required this.id,
    required this.memberId,
    required this.year,
    required this.memo,
  });

  final int? version;
  final String id;
  final String memberId;
  final int year;
  final String memo;

  MemberEvent copyWith({
    int? version,
    String? id,
    String? memberId,
    int? year,
    String? memo,
  }) {
    return MemberEvent(
      version: version ?? this.version,
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [version, id, memberId, year, memo];
}
