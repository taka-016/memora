import 'package:equatable/equatable.dart';
import 'package:memora/domain/value_objects/location.dart';

class RouteSegmentDetail extends Equatable {
  final List<Location> polyline;
  final int distanceMeters;
  final int durationSeconds;
  final List<String> instructions;

  const RouteSegmentDetail({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instructions,
  });

  const RouteSegmentDetail.empty()
    : polyline = const <Location>[],
      distanceMeters = 0,
      durationSeconds = 0,
      instructions = const <String>[];

  RouteSegmentDetail copyWith({
    List<Location>? polyline,
    int? distanceMeters,
    int? durationSeconds,
    List<String>? instructions,
  }) {
    return RouteSegmentDetail(
      polyline: polyline ?? this.polyline,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  List<Object?> get props => [
    polyline,
    distanceMeters,
    durationSeconds,
    instructions,
  ];
}
