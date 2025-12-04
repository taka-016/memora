import 'package:equatable/equatable.dart';
import 'package:memora/core/enums/travel_mode.dart';

class RouteDto extends Equatable {
  const RouteDto({
    required this.tripId,
    required this.orderIndex,
    required this.departurePinId,
    required this.arrivalPinId,
    required this.travelMode,
    this.distanceMeters,
    this.durationSeconds,
    this.instructions,
    this.polyline,
  });

  final String tripId;
  final int orderIndex;
  final String departurePinId;
  final String arrivalPinId;
  final TravelMode travelMode;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? instructions;
  final String? polyline;

  RouteDto copyWith({
    String? tripId,
    int? orderIndex,
    String? departurePinId,
    String? arrivalPinId,
    TravelMode? travelMode,
    int? distanceMeters,
    int? durationSeconds,
    String? instructions,
    String? polyline,
  }) {
    return RouteDto(
      tripId: tripId ?? this.tripId,
      orderIndex: orderIndex ?? this.orderIndex,
      departurePinId: departurePinId ?? this.departurePinId,
      arrivalPinId: arrivalPinId ?? this.arrivalPinId,
      travelMode: travelMode ?? this.travelMode,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      instructions: instructions ?? this.instructions,
      polyline: polyline ?? this.polyline,
    );
  }

  @override
  List<Object?> get props => [
    tripId,
    orderIndex,
    departurePinId,
    arrivalPinId,
    travelMode,
    distanceMeters,
    durationSeconds,
    instructions,
    polyline,
  ];
}
