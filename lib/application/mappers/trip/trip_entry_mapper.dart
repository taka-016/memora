import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/itinerary_item_mapper.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class TripEntryMapper {
  static TripEntry toEntity(TripEntryDto dto) {
    final pinDtos = dto.pins ?? const <PinDto>[];
    final locationDtos = dto.locations ?? const <LocationDto>[];
    final taskDtos = dto.tasks ?? const <TaskDto>[];
    final itineraryItemDtos = dto.itineraryItems ?? const <ItineraryItemDto>[];
    return TripEntry(
      id: dto.id,
      groupId: dto.groupId,
      year: dto.year,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
      pins: PinMapper.toEntityList(pinDtos),
      locations: LocationMapper.toEntityList(locationDtos),
      tasks: TaskMapper.toEntityList(taskDtos),
      itineraryItems: ItineraryItemMapper.toEntityList(itineraryItemDtos),
    );
  }

  static List<TripEntry> toEntityList(List<TripEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
