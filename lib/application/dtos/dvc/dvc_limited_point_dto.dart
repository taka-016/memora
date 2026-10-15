import 'package:equatable/equatable.dart';

class DvcLimitedPointDto extends Equatable {
  const DvcLimitedPointDto({
    required this.id,
    required this.groupId,
    required this.contractId,
    required this.startYearMonth,
    required this.endYearMonth,
    required this.point,
    this.memo,
  });

  final String id;
  final String groupId;
  final String contractId;
  final DateTime startYearMonth;
  final DateTime endYearMonth;
  final int point;
  final String? memo;

  DvcLimitedPointDto copyWith({
    String? id,
    String? groupId,
    String? contractId,
    DateTime? startYearMonth,
    DateTime? endYearMonth,
    int? point,
    String? memo,
  }) {
    return DvcLimitedPointDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      contractId: contractId ?? this.contractId,
      startYearMonth: startYearMonth ?? this.startYearMonth,
      endYearMonth: endYearMonth ?? this.endYearMonth,
      point: point ?? this.point,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    contractId,
    startYearMonth,
    endYearMonth,
    point,
    memo,
  ];
}
