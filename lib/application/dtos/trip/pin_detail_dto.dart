import 'package:equatable/equatable.dart';

class PinDetailDto extends Equatable {
  const PinDetailDto({
    required this.pinId,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
  });

  final String pinId;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? memo;

  PinDetailDto copyWith({
    String? pinId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
  }) {
    return PinDetailDto(
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
