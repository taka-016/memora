import 'package:equatable/equatable.dart';
import 'package:memora/core/models/coordinate.dart';

class LocationCandidateDto extends Equatable {
  const LocationCandidateDto({
    required this.name,
    required this.address,
    required this.coordinate,
  });

  final String name;
  final String address;
  final Coordinate coordinate;

  @override
  List<Object?> get props => [name, address, coordinate];
}
