import 'package:equatable/equatable.dart';
import 'package:memora/domain/value_objects/location.dart';

class LocationCandidateDto extends Equatable {
  const LocationCandidateDto({
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
