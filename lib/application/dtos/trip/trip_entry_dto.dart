import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

class TripEntryDto extends Equatable {
  const TripEntryDto({
    required this.id,
    required this.groupId,
    required this.year,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
    this.pins,
    this.tasks,
  });

  final String id;
  final String groupId;
  final int year;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? memo;
  final List<PinDto>? pins;
  final List<TaskDto>? tasks;

  TripEntryDto copyWith({
    String? id,
    String? groupId,
    int? year,
    Object? name = copyWithPlaceholder,
    Object? startDate = copyWithPlaceholder,
    Object? endDate = copyWithPlaceholder,
    String? memo,
    Object? pins = copyWithPlaceholder,
    Object? tasks = copyWithPlaceholder,
  }) {
    return TripEntryDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      name: resolveCopyWithValue<String>(name, this.name, 'name'),
      startDate: resolveCopyWithValue<DateTime>(
        startDate,
        this.startDate,
        'startDate',
      ),
      endDate: resolveCopyWithValue<DateTime>(endDate, this.endDate, 'endDate'),
      memo: memo ?? this.memo,
      pins: resolveCopyWithValue<List<PinDto>>(pins, this.pins, 'pins'),
      tasks: resolveCopyWithValue<List<TaskDto>>(tasks, this.tasks, 'tasks'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    year,
    name,
    startDate,
    endDate,
    memo,
    pins,
    tasks,
  ];
}
