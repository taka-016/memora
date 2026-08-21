import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

enum TripManagementLoadStatus { initialLoading, refreshing, success, error }

class TripManagementQuery extends Equatable {
  const TripManagementQuery({required this.groupId, required this.year});

  final String groupId;
  final int year;

  @override
  List<Object?> get props => [groupId, year];
}

class TripManagementState extends Equatable {
  const TripManagementState({
    this.tripEntries = const [],
    this.groupMembers = const [],
    this.tripEntriesStatus = TripManagementLoadStatus.initialLoading,
    this.groupMembersStatus = TripManagementLoadStatus.initialLoading,
    this.tripEntriesError,
    this.groupMembersError,
  });

  final List<TripEntryDto> tripEntries;
  final List<GroupMemberDto> groupMembers;
  final TripManagementLoadStatus tripEntriesStatus;
  final TripManagementLoadStatus groupMembersStatus;
  final Object? tripEntriesError;
  final Object? groupMembersError;

  bool get isInitialLoading =>
      tripEntriesStatus == TripManagementLoadStatus.initialLoading ||
      groupMembersStatus == TripManagementLoadStatus.initialLoading;

  TripManagementState copyWith({
    List<TripEntryDto>? tripEntries,
    List<GroupMemberDto>? groupMembers,
    TripManagementLoadStatus? tripEntriesStatus,
    TripManagementLoadStatus? groupMembersStatus,
    Object? tripEntriesError,
    bool clearTripEntriesError = false,
    Object? groupMembersError,
    bool clearGroupMembersError = false,
  }) {
    return TripManagementState(
      tripEntries: tripEntries ?? this.tripEntries,
      groupMembers: groupMembers ?? this.groupMembers,
      tripEntriesStatus: tripEntriesStatus ?? this.tripEntriesStatus,
      groupMembersStatus: groupMembersStatus ?? this.groupMembersStatus,
      tripEntriesError: clearTripEntriesError
          ? null
          : tripEntriesError ?? this.tripEntriesError,
      groupMembersError: clearGroupMembersError
          ? null
          : groupMembersError ?? this.groupMembersError,
    );
  }

  @override
  List<Object?> get props => [
    tripEntries,
    groupMembers,
    tripEntriesStatus,
    groupMembersStatus,
    tripEntriesError,
    groupMembersError,
  ];
}
