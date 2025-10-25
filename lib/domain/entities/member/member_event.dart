import 'package:equatable/equatable.dart';

class MemberEvent extends Equatable {
  const MemberEvent({
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

  MemberEvent copyWith({
    String? id,
    String? memberId,
    String? type,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return MemberEvent(
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
