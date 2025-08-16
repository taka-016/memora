import 'package:memora/domain/value-objects/location.dart';

class LocationState {
  final Location? location;
  final DateTime? lastUpdated;

  const LocationState({this.location, this.lastUpdated});

  LocationState copyWith({Location? location, DateTime? lastUpdated}) {
    return LocationState(
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
