import 'package:equatable/equatable.dart';
import 'package:memora/domain/entities/pin_detail.dart';

class Pin extends Equatable {
  Pin({
    required this.id,
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
  }) : details = List.unmodifiable(details ?? const []),
       assert(() {
         final start = visitStartDate;
         final end = visitEndDate;
         if (start == null || end == null) {
           return true;
         }
         return !end.isBefore(start);
       }(), '訪問終了日時は訪問開始日時以降でなければなりません') {
    if (this.details.isNotEmpty &&
        (visitStartDate == null || visitEndDate == null)) {
      throw ArgumentError('詳細予定を追加する場合は訪問開始日時と訪問終了日時が必要です');
    }
    for (final detail in this.details) {
      _validateDetailPeriod(detail);
    }
  }

  final String id;
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
    String? id,
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
      id: id ?? this.id,
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

  Pin addDetail(PinDetail detail) {
    if (visitStartDate == null || visitEndDate == null) {
      throw ArgumentError('詳細予定を追加する場合は訪問開始日時と訪問終了日時が必要です');
    }
    _validateDetailPeriod(detail);
    final updatedDetails = List<PinDetail>.from(details)..add(detail);
    return copyWith(details: updatedDetails);
  }

  void _validateDetailPeriod(PinDetail detail) {
    final visitStart = visitStartDate;
    final visitEnd = visitEndDate;
    final detailStart = detail.detailStartDate;
    final detailEnd = detail.detailEndDate;

    if (detailStart != null) {
      if (visitStart != null && detailStart.isBefore(visitStart)) {
        throw ArgumentError('詳細予定の開始日時は訪問開始日時以降でなければなりません');
      }
      if (visitEnd != null && detailStart.isAfter(visitEnd)) {
        throw ArgumentError('詳細予定の開始日時は訪問終了日時以前でなければなりません');
      }
    }

    if (detailEnd != null) {
      if (visitEnd != null && detailEnd.isAfter(visitEnd)) {
        throw ArgumentError('詳細予定の終了日時は訪問終了日時以前でなければなりません');
      }
      if (visitStart != null && detailEnd.isBefore(visitStart)) {
        throw ArgumentError('詳細予定の終了日時は訪問開始日時以降でなければなりません');
      }
    }
  }

  @override
  List<Object?> get props => [
    id,
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
