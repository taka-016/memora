import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/domain/entities/pin.dart';

class PinMapper {
  static PinDto toDto(Pin entity) {
    return PinDto(
      id: entity.id,
      pinId: entity.pinId,
      tripId: entity.tripId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      locationName: entity.locationName,
      visitStartDate: entity.visitStartDate,
      visitEndDate: entity.visitEndDate,
      visitMemo: entity.visitMemo,
    );
  }

  static Pin toEntity(PinDto dto) {
    return Pin(
      id: dto.id ?? '',
      pinId: dto.pinId,
      tripId: dto.tripId!,
      groupId: dto.groupId!,
      latitude: dto.latitude,
      longitude: dto.longitude,
      locationName: dto.locationName,
      visitStartDate: dto.visitStartDate,
      visitEndDate: dto.visitEndDate,
      visitMemo: dto.visitMemo,
    );
  }

  static List<PinDto> toDtoList(List<Pin> entities) {
    return entities.map(toDto).toList();
  }

  static List<Pin> toEntityList(List<PinDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
