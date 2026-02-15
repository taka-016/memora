import 'package:equatable/equatable.dart';

class DvcPointUsage extends Equatable {
  const DvcPointUsage({
    required this.id,
    required this.groupId,
    required this.usageYearMonth,
    required this.usedPoint,
    this.memo,
  });

  final String id;
  final String groupId;
  final DateTime usageYearMonth;
  final int usedPoint;
  final String? memo;

  DvcPointUsage copyWith({
    String? id,
    String? groupId,
    DateTime? usageYearMonth,
    int? usedPoint,
    String? memo,
  }) {
    return DvcPointUsage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      usageYearMonth: usageYearMonth ?? this.usageYearMonth,
      usedPoint: usedPoint ?? this.usedPoint,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, groupId, usageYearMonth, usedPoint, memo];
}
