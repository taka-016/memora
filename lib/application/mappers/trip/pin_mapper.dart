import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/entities/trip/pin.dart';

class PinMapper {
  static Pin toEntity(PinDto dto) {
    return Pin(
      pinId: dto.pinId,
      tripId: dto.tripId ?? '',
      groupId: dto.groupId ?? '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      locationName: dto.locationName,
      visitStartDate: dto.visitStartDate,
      visitEndDate: dto.visitEndDate,
      visitMemo: dto.visitMemo,
    );
  }

  static List<Pin> toEntityList(List<PinDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
