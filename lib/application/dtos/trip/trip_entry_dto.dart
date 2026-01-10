import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

class TripEntryDto extends Equatable {
  const TripEntryDto({
    required this.id,
    required this.groupId,
    required this.tripYear,
    this.tripName,
    this.tripStartDate,
    this.tripEndDate,
    this.tripMemo,
    this.pins,
    this.routes,
    this.tasks,
  });

  final String id;
  final String groupId;
  final int tripYear;
  final String? tripName;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String? tripMemo;
  final List<PinDto>? pins;
  final List<RouteDto>? routes;
  final List<TaskDto>? tasks;

  TripEntryDto copyWith({
    String? id,
    String? groupId,
    int? tripYear,
    Object? tripName = copyWithPlaceholder,
    Object? tripStartDate = copyWithPlaceholder,
    Object? tripEndDate = copyWithPlaceholder,
    Object? tripMemo = copyWithPlaceholder,
    Object? pins = copyWithPlaceholder,
    Object? routes = copyWithPlaceholder,
    Object? tasks = copyWithPlaceholder,
  }) {
    return TripEntryDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripYear: tripYear ?? this.tripYear,
      tripName: resolveCopyWithValue<String>(
        tripName,
        this.tripName,
        'tripName',
      ),
      tripStartDate: resolveCopyWithValue<DateTime>(
        tripStartDate,
        this.tripStartDate,
        'tripStartDate',
      ),
      tripEndDate: resolveCopyWithValue<DateTime>(
        tripEndDate,
        this.tripEndDate,
        'tripEndDate',
      ),
      tripMemo: resolveCopyWithValue<String>(
        tripMemo,
        this.tripMemo,
        'tripMemo',
      ),
      pins: resolveCopyWithValue<List<PinDto>>(pins, this.pins, 'pins'),
      routes: resolveCopyWithValue<List<RouteDto>>(
        routes,
        this.routes,
        'routes',
      ),
      tasks: resolveCopyWithValue<List<TaskDto>>(tasks, this.tasks, 'tasks'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    tripYear,
    tripName,
    tripStartDate,
    tripEndDate,
    tripMemo,
    pins,
    routes,
    tasks,
  ];
}
