import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/domain/entities/trip/location.dart';

class LocationMapper {
  static Location toEntity(LocationDto dto) {
    return Location(
      id: dto.id,
      tripId: dto.tripId,
      groupId: dto.groupId,
      name: dto.name,
      latitude: dto.latitude,
      longitude: dto.longitude,
    );
  }

  static LocationDto toDto(Location entity) {
    return LocationDto(
      id: entity.id,
      tripId: entity.tripId,
      groupId: entity.groupId,
      name: entity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  static List<Location> toEntityList(List<LocationDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<LocationDto> toDtoList(List<Location> entities) {
    return entities.map(toDto).toList();
  }
}
