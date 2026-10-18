import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

class TripEntryDto extends Equatable {
  const TripEntryDto({
    this.version,
    required this.id,
    required this.groupId,
    required this.year,
    this.name,
    this.startDate,
    this.endDate,
    this.memo,
    this.locations,
    this.tasks,
    this.itineraryItems,
  });

  final int? version;
  final String id;
  final String groupId;
  final int year;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? memo;
  final List<LocationDto>? locations;
  final List<TaskDto>? tasks;
  final List<ItineraryItemDto>? itineraryItems;

  TripEntryDto copyWith({
    int? version,
    String? id,
    String? groupId,
    int? year,
    Object? name = copyWithPlaceholder,
    Object? startDate = copyWithPlaceholder,
    Object? endDate = copyWithPlaceholder,
    String? memo,
    Object? locations = copyWithPlaceholder,
    Object? tasks = copyWithPlaceholder,
    Object? itineraryItems = copyWithPlaceholder,
  }) {
    return TripEntryDto(
      version: version ?? this.version,
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
      locations: resolveCopyWithValue<List<LocationDto>>(
        locations,
        this.locations,
        'locations',
      ),
      tasks: resolveCopyWithValue<List<TaskDto>>(tasks, this.tasks, 'tasks'),
      itineraryItems: resolveCopyWithValue<List<ItineraryItemDto>>(
        itineraryItems,
        this.itineraryItems,
        'itineraryItems',
      ),
    );
  }

  @override
  List<Object?> get props => [
    version,
    id,
    groupId,
    year,
    name,
    startDate,
    endDate,
    memo,
    locations,
    tasks,
    itineraryItems,
  ];
}
