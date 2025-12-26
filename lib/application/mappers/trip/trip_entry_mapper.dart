import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/route_mapper.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class TripEntryMapper {
  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<PinDto> pins = const [],
    List<RouteDto> routes = const [],
    List<TaskDto> tasks = const [],
  }) {
    final data = doc.data() ?? {};
    final tripStartTimestamp = data['tripStartDate'] as Timestamp?;
    final tripEndTimestamp = data['tripEndDate'] as Timestamp?;
    final tripStartDate = tripStartTimestamp?.toDate();
    final tripEndDate = tripEndTimestamp?.toDate();
    return TripEntryDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      tripYear:
          data['tripYear'] as int? ??
          tripStartDate?.year ??
          DateTime.now().year,
      tripName: data['tripName'] as String?,
      tripStartDate: tripStartDate,
      tripEndDate: tripEndDate,
      tripMemo: data['tripMemo'] as String?,
      pins: pins,
      routes: routes,
      tasks: tasks,
    );
  }

  static TripEntry toEntity(TripEntryDto dto) {
    final pinDtos = dto.pins ?? const <PinDto>[];
    final routeDtos = dto.routes ?? const <RouteDto>[];
    final taskDtos = dto.tasks ?? const <TaskDto>[];
    return TripEntry(
      id: dto.id,
      groupId: dto.groupId,
      tripYear: dto.tripYear,
      tripName: dto.tripName,
      tripStartDate: dto.tripStartDate,
      tripEndDate: dto.tripEndDate,
      tripMemo: dto.tripMemo,
      pins: PinMapper.toEntityList(pinDtos),
      routes: RouteMapper.toEntityList(routeDtos),
      tasks: TaskMapper.toEntityList(taskDtos),
    );
  }

  static List<TripEntry> toEntityList(List<TripEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
