import 'package:equatable/equatable.dart';

class LocationCandidate extends Equatable {
  const LocationCandidate({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  LocationCandidate copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return LocationCandidate(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [name, address, latitude, longitude];
}
