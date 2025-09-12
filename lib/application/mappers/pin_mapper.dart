import '../dtos/pin/pin_dto.dart';
import '../../domain/entities/pin.dart';

class PinMapper {
  static PinDto toDto(Pin entity) {
    return PinDto(
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

  static Pin toEntity(PinDto dto, {String id = ''}) {
    return Pin(
      id: id,
      pinId: dto.pinId,
      tripId: dto.tripId,
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

  static List<Pin> toEntityList(List<PinDto> dtos, {List<String>? ids}) {
    return dtos.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      final id = ids != null && index < ids.length ? ids[index] : '';
      return toEntity(dto, id: id);
    }).toList();
  }
}
