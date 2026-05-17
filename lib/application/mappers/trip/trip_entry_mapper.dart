import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class TripEntryMapper {
  static TripEntry toEntity(TripEntryDto dto) {
    final pinDtos = dto.pins ?? const <PinDto>[];
    final taskDtos = dto.tasks ?? const <TaskDto>[];
    return TripEntry(
      id: dto.id,
      groupId: dto.groupId,
      year: dto.year,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
      pins: PinMapper.toEntityList(pinDtos),
      tasks: TaskMapper.toEntityList(taskDtos),
    );
  }

  static List<TripEntry> toEntityList(List<TripEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
