import 'package:equatable/equatable.dart';
import 'package:memora/domain/value_objects/location.dart';

class LocationState extends Equatable {
  final Location? location;
  final DateTime? lastUpdated;

  const LocationState({this.location, this.lastUpdated});

  LocationState copyWith({Location? location, DateTime? lastUpdated}) {
    return LocationState(
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [location, lastUpdated];
}
