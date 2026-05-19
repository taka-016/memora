import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart' as entity;

class ItineraryItemMapper {
  static entity.ItineraryItem toEntity(ItineraryItemDto dto) {
    return entity.ItineraryItem(
      id: dto.id,
      tripId: dto.tripId,
      name: dto.name,
      startDateTime: dto.startDateTime,
      endDateTime: dto.endDateTime,
      memo: dto.memo,
    );
  }

  static List<entity.ItineraryItem> toEntityList(List<ItineraryItemDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
