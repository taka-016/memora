import 'package:equatable/equatable.dart';
import 'package:memora/core/models/coordinate.dart';

class LocationState extends Equatable {
  final Coordinate? coordinate;
  final DateTime? lastUpdated;

  const LocationState({this.coordinate, this.lastUpdated});

  LocationState copyWith({Coordinate? coordinate, DateTime? lastUpdated}) {
    return LocationState(
      coordinate: coordinate ?? this.coordinate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [coordinate, lastUpdated];
}
