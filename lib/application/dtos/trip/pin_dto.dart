import 'package:equatable/equatable.dart';
import 'package:memora/core/models/coordinate.dart';

class PinDto extends Equatable {
  const PinDto({
    required this.pinId,
    this.tripId,
    this.groupId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.visitStartDateTime,
    this.visitEndDateTime,
    this.memo,
  });

  final String pinId;
  final String? tripId;
  final String? groupId;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime? visitStartDateTime;
  final DateTime? visitEndDateTime;
  final String? memo;

  Coordinate get coordinate {
    return Coordinate(latitude: latitude, longitude: longitude);
  }

  PinDto copyWith({
    String? pinId,
    String? tripId,
    String? groupId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? visitStartDateTime,
    DateTime? visitEndDateTime,
    String? memo,
  }) {
    return PinDto(
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      visitStartDateTime: visitStartDateTime ?? this.visitStartDateTime,
      visitEndDateTime: visitEndDateTime ?? this.visitEndDateTime,
      memo: memo ?? this.memo,
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
    visitStartDateTime,
    visitEndDateTime,
    memo,
  ];
}
