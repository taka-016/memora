import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';
import 'package:memora/core/models/coordinate.dart';

class LocationDto extends Equatable {
  const LocationDto({
    required this.id,
    required this.tripId,
    required this.groupId,
    required this.latitude,
    required this.longitude,
    this.name,
  });

  final String id;
  final String tripId;
  final String groupId;
  final String? name;
  final double latitude;
  final double longitude;

  Coordinate get coordinate =>
      Coordinate(latitude: latitude, longitude: longitude);

  LocationDto copyWith({
    String? id,
    String? tripId,
    String? groupId,
    Object? name = copyWithPlaceholder,
    double? latitude,
    double? longitude,
  }) {
    return LocationDto(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      name: resolveCopyWithValue<String>(name, this.name, 'name'),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [id, tripId, groupId, name, latitude, longitude];
}
