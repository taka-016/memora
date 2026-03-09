import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/value_objects/location.dart';

class Pin extends Equatable {
  Pin({
    required this.pinId,
    required this.tripId,
    required this.groupId,
    double? latitude,
    double? longitude,
    Location? location,
    this.locationName,
    this.visitStartDate,
    this.visitEndDate,
    this.visitMemo,
  }) : location = _resolveLocation(
         location: location,
         latitude: latitude,
         longitude: longitude,
       ) {
    final start = visitStartDate;
    final end = visitEndDate;
    if (start != null && end != null && end.isBefore(start)) {
      throw ValidationException('訪問終了日時は訪問開始日時以降でなければなりません');
    }
  }

  final String pinId;
  final String tripId;
  final String groupId;
  final Location location;
  final String? locationName;
  final DateTime? visitStartDate;
  final DateTime? visitEndDate;
  final String? visitMemo;

  double get latitude => location.latitude;
  double get longitude => location.longitude;

  Pin copyWith({
    String? pinId,
    String? tripId,
    String? groupId,
    double? latitude,
    double? longitude,
    Location? location,
    String? locationName,
    DateTime? visitStartDate,
    DateTime? visitEndDate,
    String? visitMemo,
  }) {
    final nextLocation =
        location ??
        ((latitude != null || longitude != null)
            ? Location(
                latitude: latitude ?? this.latitude,
                longitude: longitude ?? this.longitude,
              )
            : this.location);

    return Pin(
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      location: nextLocation,
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
    location,
    locationName,
    visitStartDate,
    visitEndDate,
    visitMemo,
  ];

  static Location _resolveLocation({
    required Location? location,
    required double? latitude,
    required double? longitude,
  }) {
    if (location != null) {
      return location;
    }
    if (latitude == null || longitude == null) {
      throw ValidationException('位置情報はlocationまたは緯度・経度の指定が必要です');
    }
    return Location(latitude: latitude, longitude: longitude);
  }
}
