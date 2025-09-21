import 'package:equatable/equatable.dart';

class PinDetail extends Equatable {
  PinDetail({
    required this.pinId,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
  }) {
    // 詳細開始日時と終了日時の順序検証
    final start = startDate;
    final end = endDate;
    if (start != null && end != null && end.isBefore(start)) {
      throw ArgumentError('詳細終了日時は詳細開始日時以降でなければなりません');
    }
  }

  final String pinId;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? memo;

  PinDetail copyWith({
    String? pinId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return PinDetail(
      pinId: pinId ?? this.pinId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [pinId, name, startDate, endDate, memo];
}
