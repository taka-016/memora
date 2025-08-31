import 'package:equatable/equatable.dart';

import 'location.dart';

class LocationCandidate extends Equatable {
  const LocationCandidate({
    required this.name,
    required this.address,
    required this.location,
  });

  final String name;
  final String address;
  final Location location;

  @override
  List<Object?> get props => [name, address, location];
}
