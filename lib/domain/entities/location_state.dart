class LocationState {
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  const LocationState({this.latitude, this.longitude, this.lastUpdated});

  LocationState copyWith({
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
