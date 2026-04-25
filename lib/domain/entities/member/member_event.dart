import 'package:equatable/equatable.dart';

class MemberEvent extends Equatable {
  const MemberEvent({
    required this.id,
    required this.memberId,
    required this.year,
    required this.memo,
  });

  final String id;
  final String memberId;
  final int year;
  final String memo;

  MemberEvent copyWith({
    String? id,
    String? memberId,
    int? year,
    String? memo,
  }) {
    return MemberEvent(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, memberId, year, memo];
}
