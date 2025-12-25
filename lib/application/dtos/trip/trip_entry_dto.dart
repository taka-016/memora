import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

const _copyWithPlaceholder = Object();

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
    Object? tripName = _copyWithPlaceholder,
    Object? tripStartDate = _copyWithPlaceholder,
    Object? tripEndDate = _copyWithPlaceholder,
    Object? tripMemo = _copyWithPlaceholder,
    Object? pins = _copyWithPlaceholder,
    Object? routes = _copyWithPlaceholder,
    Object? tasks = _copyWithPlaceholder,
  }) {
    return TripEntryDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripYear: tripYear ?? this.tripYear,
      tripName: identical(tripName, _copyWithPlaceholder)
          ? this.tripName
          : tripName as String?,
      tripStartDate: identical(tripStartDate, _copyWithPlaceholder)
          ? this.tripStartDate
          : tripStartDate as DateTime?,
      tripEndDate: identical(tripEndDate, _copyWithPlaceholder)
          ? this.tripEndDate
          : tripEndDate as DateTime?,
      tripMemo: identical(tripMemo, _copyWithPlaceholder)
          ? this.tripMemo
          : tripMemo as String?,
      pins: identical(pins, _copyWithPlaceholder)
          ? this.pins
          : pins as List<PinDto>?,
      routes: identical(routes, _copyWithPlaceholder)
          ? this.routes
          : routes as List<RouteDto>?,
      tasks: identical(tasks, _copyWithPlaceholder)
          ? this.tasks
          : tasks as List<TaskDto>?,
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
