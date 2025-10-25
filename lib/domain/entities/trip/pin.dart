import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Pin extends Equatable {
  Pin({
    required this.pinId,
    required this.tripId,
    required this.groupId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.visitStartDate,
    this.visitEndDate,
    this.visitMemo,
    List<PinDetail>? details,
  }) : details = List.unmodifiable(details ?? const []) {
    final start = visitStartDate;
    final end = visitEndDate;
    if (start != null && end != null && end.isBefore(start)) {
      throw ValidationException('訪問終了日時は訪問開始日時以降でなければなりません');
    }
    if (this.details.isNotEmpty &&
        (visitStartDate == null || visitEndDate == null)) {
      throw ValidationException('詳細予定を追加する場合は訪問開始日時と訪問終了日時が必要です');
    }
    for (final detail in this.details) {
      _validateDetailPeriod(detail);
    }
  }

  final String pinId;
  final String tripId;
  final String groupId;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime? visitStartDate;
  final DateTime? visitEndDate;
  final String? visitMemo;
  final List<PinDetail> details;

  Pin copyWith({
    String? pinId,
    String? tripId,
    String? groupId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? visitStartDate,
    DateTime? visitEndDate,
    String? visitMemo,
    List<PinDetail>? details,
  }) {
    return Pin(
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      visitStartDate: visitStartDate ?? this.visitStartDate,
      visitEndDate: visitEndDate ?? this.visitEndDate,
      visitMemo: visitMemo ?? this.visitMemo,
      details: details ?? this.details,
    );
  }

  void _validateDetailPeriod(PinDetail detail) {
    if (detail.startDate != null) {
      if (detail.startDate!.isBefore(visitStartDate!) ||
          detail.startDate!.isAfter(visitEndDate!)) {
        throw ValidationException('詳細予定の開始日時は旅行期間内でなければなりません');
      }
    }
    if (detail.endDate != null) {
      if (detail.endDate!.isBefore(visitStartDate!) ||
          detail.endDate!.isAfter(visitEndDate!)) {
        throw ValidationException('詳細予定の終了日時は旅行期間内でなければなりません');
      }
    }
  }

  @override
  List<Object?> get props => [
    pinId,
    tripId,
    groupId,
    latitude,
    longitude,
    locationName,
    visitStartDate,
    visitEndDate,
    visitMemo,
    details,
  ];
}
