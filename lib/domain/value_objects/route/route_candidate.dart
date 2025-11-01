import 'package:equatable/equatable.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';

class RouteCandidate extends Equatable {
  final String? description;
  final String? localizedDistanceText;
  final String? localizedDurationText;
  final List<RouteLeg> legs;
  final List<String> warnings;

  const RouteCandidate({
    this.description,
    this.localizedDistanceText,
    this.localizedDurationText,
    required this.legs,
    required this.warnings,
  });

  @override
  List<Object?> get props => [
    description,
    localizedDistanceText,
    localizedDurationText,
    legs,
    warnings,
  ];
}
