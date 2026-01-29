import 'package:equatable/equatable.dart';

class PinDto extends Equatable {
  const PinDto({
    required this.pinId,
    this.tripId,
    this.groupId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.visitStartDate,
    this.visitEndDate,
    this.visitMemo,
  });

  final String pinId;
  final String? tripId;
  final String? groupId;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime? visitStartDate;
  final DateTime? visitEndDate;
  final String? visitMemo;

  PinDto copyWith({
    String? pinId,
    String? tripId,
    String? groupId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? visitStartDate,
    DateTime? visitEndDate,
    String? visitMemo,
  }) {
    return PinDto(
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      visitStartDate: visitStartDate ?? this.visitStartDate,
      visitEndDate: visitEndDate ?? this.visitEndDate,
      visitMemo: visitMemo ?? this.visitMemo,
    );
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
  ];
}
