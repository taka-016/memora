import 'package:equatable/equatable.dart';

class MemberEventDto extends Equatable {
  const MemberEventDto({
    required this.id,
    required this.memberId,
    required this.type,
    this.name,
    required this.startDate,
    required this.endDate,
    this.memo,
  });

  final String id;
  final String memberId;
  final String type;
  final String? name;
  final DateTime startDate;
  final DateTime endDate;
  final String? memo;

  MemberEventDto copyWith({
    String? id,
    String? memberId,
    String? type,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return MemberEventDto(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    memberId,
    type,
    name,
    startDate,
    endDate,
    memo,
  ];
}
