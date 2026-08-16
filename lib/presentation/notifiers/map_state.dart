import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

enum MapLoadStatus { initial, loading, success, error }

enum MapTripOperationStatus { idle, loading, success, error }

class MapState extends Equatable {
  const MapState({
    this.groups = const [],
    this.selectedGroup,
    this.locations = const [],
    this.trips = const [],
    this.focusedLocation,
    this.groupsStatus = MapLoadStatus.initial,
    this.locationsStatus = MapLoadStatus.initial,
    this.tripsStatus = MapLoadStatus.initial,
    this.tripOperationStatus = MapTripOperationStatus.idle,
    this.groupsErrorMessage = '',
    this.locationsErrorMessage = '',
    this.tripsErrorMessage = '',
    this.tripOperationErrorMessage = '',
  });

  final List<GroupDto> groups;
  final GroupDto? selectedGroup;
  final List<LocationDto> locations;
  final List<TripEntryDto> trips;
  final LocationDto? focusedLocation;
  final MapLoadStatus groupsStatus;
  final MapLoadStatus locationsStatus;
  final MapLoadStatus tripsStatus;
  final MapTripOperationStatus tripOperationStatus;
  final String groupsErrorMessage;
  final String locationsErrorMessage;
  final String tripsErrorMessage;
  final String tripOperationErrorMessage;

  bool get isGroupDataLoading =>
      locationsStatus == MapLoadStatus.loading ||
      tripsStatus == MapLoadStatus.loading;

  MapState copyWith({
    List<GroupDto>? groups,
    GroupDto? selectedGroup,
    bool clearSelectedGroup = false,
    List<LocationDto>? locations,
    List<TripEntryDto>? trips,
    LocationDto? focusedLocation,
    bool clearFocusedLocation = false,
    MapLoadStatus? groupsStatus,
    MapLoadStatus? locationsStatus,
    MapLoadStatus? tripsStatus,
    MapTripOperationStatus? tripOperationStatus,
    String? groupsErrorMessage,
    String? locationsErrorMessage,
    String? tripsErrorMessage,
    String? tripOperationErrorMessage,
  }) {
    return MapState(
      groups: groups ?? this.groups,
      selectedGroup: clearSelectedGroup
          ? null
          : selectedGroup ?? this.selectedGroup,
      locations: locations ?? this.locations,
      trips: trips ?? this.trips,
      focusedLocation: clearFocusedLocation
          ? null
          : focusedLocation ?? this.focusedLocation,
      groupsStatus: groupsStatus ?? this.groupsStatus,
      locationsStatus: locationsStatus ?? this.locationsStatus,
      tripsStatus: tripsStatus ?? this.tripsStatus,
      tripOperationStatus: tripOperationStatus ?? this.tripOperationStatus,
      groupsErrorMessage: groupsErrorMessage ?? this.groupsErrorMessage,
      locationsErrorMessage:
          locationsErrorMessage ?? this.locationsErrorMessage,
      tripsErrorMessage: tripsErrorMessage ?? this.tripsErrorMessage,
      tripOperationErrorMessage:
          tripOperationErrorMessage ?? this.tripOperationErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    groups,
    selectedGroup,
    locations,
    trips,
    focusedLocation,
    groupsStatus,
    locationsStatus,
    tripsStatus,
    tripOperationStatus,
    groupsErrorMessage,
    locationsErrorMessage,
    tripsErrorMessage,
    tripOperationErrorMessage,
  ];
}
