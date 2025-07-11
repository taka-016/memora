import 'package:equatable/equatable.dart';

class TripEntry extends Equatable {
  const TripEntry({
    required this.id,
    required this.groupId,
    this.tripName,
    required this.tripStartDate,
    required this.tripEndDate,
    this.tripMemo,
  });

  final String id;
  final String groupId;
  final String? tripName;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String? tripMemo;

  TripEntry copyWith({
    String? id,
    String? groupId,
    String? tripName,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
    String? tripMemo,
  }) {
    return TripEntry(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripName: tripName ?? this.tripName,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      tripMemo: tripMemo ?? this.tripMemo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    tripName,
    tripStartDate,
    tripEndDate,
    tripMemo,
  ];
}
