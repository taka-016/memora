import 'package:equatable/equatable.dart';

class MemberEventDto extends Equatable {
  const MemberEventDto({
    required this.id,
    required this.memberId,
    required this.year,
    required this.memo,
  });

  final String id;
  final String memberId;
  final int year;
  final String memo;

  MemberEventDto copyWith({
    String? id,
    String? memberId,
    int? year,
    String? memo,
  }) {
    return MemberEventDto(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      year: year ?? this.year,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, memberId, year, memo];
}
