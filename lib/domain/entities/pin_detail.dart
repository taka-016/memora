import 'package:equatable/equatable.dart';

class PinDetail extends Equatable {
  PinDetail({
    required this.id,
    required this.detailId,
    required this.pinId,
    required this.tripId,
    required this.groupId,
    this.detailName,
    this.detailStartDate,
    this.detailEndDate,
    this.detailMemo,
  }) : assert(() {
         final start = detailStartDate;
         final end = detailEndDate;
         if (start == null || end == null) {
           return true;
         }
         return !end.isBefore(start);
       }(), '詳細終了日時は詳細開始日時以降でなければなりません');

  final String id;
  final String detailId;
  final String pinId;
  final String tripId;
  final String groupId;
  final String? detailName;
  final DateTime? detailStartDate;
  final DateTime? detailEndDate;
  final String? detailMemo;

  PinDetail copyWith({
    String? id,
    String? detailId,
    String? pinId,
    String? tripId,
    String? groupId,
    String? detailName,
    DateTime? detailStartDate,
    DateTime? detailEndDate,
    String? detailMemo,
  }) {
    return PinDetail(
      id: id ?? this.id,
      detailId: detailId ?? this.detailId,
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      detailName: detailName ?? this.detailName,
      detailStartDate: detailStartDate ?? this.detailStartDate,
      detailEndDate: detailEndDate ?? this.detailEndDate,
      detailMemo: detailMemo ?? this.detailMemo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    detailId,
    pinId,
    tripId,
    groupId,
    detailName,
    detailStartDate,
    detailEndDate,
    detailMemo,
  ];
}
