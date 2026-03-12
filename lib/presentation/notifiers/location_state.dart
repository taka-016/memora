import 'package:equatable/equatable.dart';
import 'package:memora/core/models/coordinate.dart';

class LocationState extends Equatable {
  final Coordinate? location;
  final DateTime? lastUpdated;

  const LocationState({this.location, this.lastUpdated});

  LocationState copyWith({Coordinate? location, DateTime? lastUpdated}) {
    return LocationState(
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [location, lastUpdated];
}
