import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

enum MapLoadStatus { initial, loading, success, error }

class MapState extends Equatable {
  const MapState({
    this.groups = const [],
    this.selectedGroup,
    this.locations = const [],
    this.trips = const [],
    this.groupsStatus = MapLoadStatus.initial,
    this.locationsStatus = MapLoadStatus.initial,
    this.tripsStatus = MapLoadStatus.initial,
    this.locationsErrorMessage = '',
    this.tripsErrorMessage = '',
  });

  final List<GroupDto> groups;
  final GroupDto? selectedGroup;
  final List<LocationDto> locations;
  final List<TripEntryDto> trips;
  final MapLoadStatus groupsStatus;
  final MapLoadStatus locationsStatus;
  final MapLoadStatus tripsStatus;
  final String locationsErrorMessage;
  final String tripsErrorMessage;

  LocationDto? get focusedLocation => locations.firstOrNull;

  bool get isGroupDataLoading =>
      locationsStatus == MapLoadStatus.loading ||
      tripsStatus == MapLoadStatus.loading;

  MapState copyWith({
    List<GroupDto>? groups,
    GroupDto? selectedGroup,
    bool clearSelectedGroup = false,
    List<LocationDto>? locations,
    List<TripEntryDto>? trips,
    MapLoadStatus? groupsStatus,
    MapLoadStatus? locationsStatus,
    MapLoadStatus? tripsStatus,
    String? locationsErrorMessage,
    String? tripsErrorMessage,
  }) {
    return MapState(
      groups: groups ?? this.groups,
      selectedGroup: clearSelectedGroup
          ? null
          : selectedGroup ?? this.selectedGroup,
      locations: locations ?? this.locations,
      trips: trips ?? this.trips,
      groupsStatus: groupsStatus ?? this.groupsStatus,
      locationsStatus: locationsStatus ?? this.locationsStatus,
      tripsStatus: tripsStatus ?? this.tripsStatus,
      locationsErrorMessage:
          locationsErrorMessage ?? this.locationsErrorMessage,
      tripsErrorMessage: tripsErrorMessage ?? this.tripsErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    groups,
    selectedGroup,
    locations,
    trips,
    groupsStatus,
    locationsStatus,
    tripsStatus,
    locationsErrorMessage,
    tripsErrorMessage,
  ];
}
