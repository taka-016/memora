import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/entities/pin_detail.dart';

class TripEntry extends Equatable {
  TripEntry({
    required this.id,
    required this.groupId,
    this.tripName,
    required this.tripStartDate,
    required this.tripEndDate,
    this.tripMemo,
    List<Pin>? pins,
  }) : pins = List.unmodifiable(pins ?? const []) {
    if (tripEndDate.isBefore(tripStartDate)) {
      throw ArgumentError('旅行の終了日は開始日以降でなければなりません');
    }
    for (final pin in this.pins) {
      _validatePinPeriod(pin);
    }
  }

  final String id;
  final String groupId;
  final String? tripName;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String? tripMemo;
  final List<Pin> pins;

  TripEntry copyWith({
    String? id,
    String? groupId,
    String? tripName,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
    String? tripMemo,
    List<Pin>? pins,
  }) {
    return TripEntry(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripName: tripName ?? this.tripName,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      tripMemo: tripMemo ?? this.tripMemo,
      pins: pins ?? this.pins,
    );
  }

  TripEntry addPin(Pin pin) {
    _validatePinPeriod(pin);
    final updatedPins = List<Pin>.from(pins)..add(pin);
    return copyWith(pins: updatedPins);
  }

  void _validatePinPeriod(Pin pin) {
    if (pin.visitStartDate != null) {
      if (pin.visitStartDate!.isBefore(tripStartDate) ||
          pin.visitStartDate!.isAfter(tripEndDate)) {
        throw ArgumentError('訪問開始日時は旅行期間内でなければなりません');
      }
    }
    if (pin.visitEndDate != null) {
      if (pin.visitEndDate!.isBefore(tripStartDate) ||
          pin.visitEndDate!.isAfter(tripEndDate)) {
        throw ArgumentError('訪問終了日時は旅行期間内でなければなりません');
      }
    }
    for (final detail in pin.details) {
      _validatePinDetailPeriod(detail);
    }
  }

  void _validatePinDetailPeriod(PinDetail detail) {
    if (detail.detailStartDate != null) {
      if (detail.detailStartDate!.isBefore(tripStartDate) ||
          detail.detailStartDate!.isAfter(tripEndDate)) {
        throw ArgumentError('詳細予定の開始日時は旅行期間内でなければなりません');
      }
    }
    if (detail.detailEndDate != null) {
      if (detail.detailEndDate!.isBefore(tripStartDate) ||
          detail.detailEndDate!.isAfter(tripEndDate)) {
        throw ArgumentError('詳細予定の終了日時は旅行期間内でなければなりません');
      }
    }
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    tripName,
    tripStartDate,
    tripEndDate,
    tripMemo,
    pins,
  ];
}
