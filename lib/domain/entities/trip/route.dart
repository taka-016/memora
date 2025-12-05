import 'package:equatable/equatable.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Route extends Equatable {
  Route({
    required this.tripId,
    required this.orderIndex,
    required this.departurePinId,
    required this.arrivalPinId,
    required this.travelMode,
    this.distanceMeters,
    this.durationSeconds,
    this.instructions,
    this.polyline,
  }) {
    _validate();
  }

  final String tripId;
  final int orderIndex;
  final String departurePinId;
  final String arrivalPinId;
  final TravelMode travelMode;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? instructions;
  final String? polyline;

  Route copyWith({
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
    return Route(
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

  void _validate() {
    if (orderIndex < 0) {
      throw ValidationException('ルートの順序は0以上でなければなりません');
    }
    if (departurePinId == arrivalPinId) {
      throw ValidationException('出発地点と到着地点は異なるピンでなければなりません');
    }
    if (distanceMeters != null && distanceMeters! < 0) {
      throw ValidationException('距離は0以上でなければなりません');
    }
    if (durationSeconds != null && durationSeconds! < 0) {
      throw ValidationException('所要時間は0以上でなければなりません');
    }
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
