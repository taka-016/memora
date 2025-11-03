import 'package:equatable/equatable.dart';
import 'package:memora/domain/value_objects/route/route_geo_point.dart';

class RouteLeg extends Equatable {
  final String? localizedDistanceText;
  final String? localizedDurationText;
  final String? primaryInstruction;
  final List<RouteGeoPoint> polylinePoints;

  const RouteLeg({
    this.localizedDistanceText,
    this.localizedDurationText,
    this.primaryInstruction,
    this.polylinePoints = const [],
  });

  @override
  List<Object?> get props => [
    localizedDistanceText,
    localizedDurationText,
    primaryInstruction,
    polylinePoints,
  ];
}
