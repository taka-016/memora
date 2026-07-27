import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/map/map_pin_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

class MapScreen extends HookConsumerWidget {
  final bool isTestEnvironment;

  const MapScreen({super.key, this.isTestEnvironment = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberNotifierProvider).member;
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final getGroupsWithMembersUsecase = useMemoized(
      () => ref.read(getGroupsWithMembersUsecaseProvider),
    );
    final getLocationsByGroupIdUsecase = useMemoized(
      () => ref.read(getLocationsByGroupIdUsecaseProvider),
    );
    final getTripEntriesUsecase = useMemoized(
      () => ref.read(getMapTripEntriesUsecaseProvider),
    );
    final getTripEntryByIdUsecase = useMemoized(
      () => ref.read(getTripEntryByIdUsecaseProvider),
    );
    final updateTripEntryUsecase = useMemoized(
      () => ref.read(updateTripEntryUsecaseProvider),
    );
    final groupLoadGeneration = useState(0);
    final groupsFuture = useMemoized(
      () => getGroupsWithMembersUsecase.execute(currentMember),
      [getGroupsWithMembersUsecase, currentMember, groupLoadGeneration.value],
    );
    final groupsSnapshot = useFuture(groupsFuture);
    final selectedGroupState = useState<GroupDto?>(null);
    final locations = useState<List<LocationDto>>([]);
    final trips = useState<List<TripEntryDto>>([]);
    final hasTripLoadError = useState(false);
    final isGroupDataLoading = useState(false);
    final focusedLocation = useState<LocationDto?>(null);
    final latestGroupLoad = useRef<Object?>(null);
    final groups = groupsSnapshot.data ?? const <GroupDto>[];
    final selectedGroup =
        selectedGroupState.value ?? (groups.length == 1 ? groups.single : null);

    void replaceUpdatedTrip(TripEntryDto updatedTrip) {
      trips.value = [
        for (final item in trips.value)
          if (item.id == updatedTrip.id) updatedTrip else item,
      ];
      locations.value = [
        ...locations.value.where(
          (location) => location.tripId != updatedTrip.id,
        ),
        ...?updatedTrip.locations,
      ];
    }

    useEffect(
      () {
        final group = selectedGroup;
        if (group == null) {
          return null;
        }

        final loadToken = Object();
        latestGroupLoad.value = loadToken;
        Future.microtask(() async {
          isGroupDataLoading.value = true;
          locations.value = const [];
          trips.value = const [];
          hasTripLoadError.value = false;
          focusedLocation.value = null;

          try {
            final fetchedLocations = await getLocationsByGroupIdUsecase.execute(
              group.id,
            );
            if (latestGroupLoad.value != loadToken) {
              return;
            }
            locations.value = fetchedLocations;
            focusedLocation.value = fetchedLocations.firstOrNull;

            try {
              final fetchedTrips = await getTripEntriesUsecase.executeByGroupId(
                group.id,
              );
              if (latestGroupLoad.value != loadToken) {
                return;
              }
              trips.value = fetchedTrips;
            } catch (e, stack) {
              if (latestGroupLoad.value != loadToken) {
                return;
              }
              hasTripLoadError.value = true;
              logger.e(
                'MapScreen.loadTrips: ${e.toString()}',
                error: e,
                stackTrace: stack,
              );
            }
          } finally {
            if (latestGroupLoad.value == loadToken) {
              isGroupDataLoading.value = false;
            }
          }
        });
        return () {
          if (latestGroupLoad.value == loadToken) {
            latestGroupLoad.value = null;
          }
        };
      },
      [getLocationsByGroupIdUsecase, getTripEntriesUsecase, selectedGroup?.id],
    );

    if (selectedGroup == null) {
      return GroupSelectionList(
        title: 'グループを選択',
        listKey: const Key('map_group_list'),
        groupsFuture: groupsFuture,
        onGroupSelected: (group) {
          selectedGroupState.value = group;
        },
        onRetry: () {
          groupLoadGeneration.value++;
        },
      );
    }

    Future<void> handleTripTapped(TripEntryDto trip) async {
      try {
        final currentTrip = await getTripEntryByIdUsecase.execute(trip.id);
        if (!context.mounted) {
          return;
        }
        final group = groups
            .where((item) => item.id == currentTrip?.groupId)
            .firstOrNull;
        if (currentTrip == null || group == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
          return;
        }

        await showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (dialogContext) => TripEditModal(
            groupId: currentTrip.groupId,
            groupMembers: group.members,
            tripEntry: currentTrip,
            year: currentTrip.year,
            isTestEnvironment: isTestEnvironment,
            onSave: (updatedTrip) async {
              await updateTripEntryUsecase.execute(updatedTrip);
              replaceUpdatedTrip(updatedTrip);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('旅行を更新しました')));
              }
            },
          ),
        );
      } catch (e, stack) {
        logger.e(
          'MapScreen.openTrip: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
        }
      }
    }

    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    final groupSelector = _MapGroupSelector(
      groups: groups,
      selectedGroup: selectedGroup,
      onSelected: (group) {
        selectedGroupState.value = group;
      },
    );

    final mapView = KeyedSubtree(
      key: ValueKey(selectedGroup.id),
      child: MapViewFactory.create(mapViewType).createMapView(
        locations: locations.value,
        focusedLocation: focusedLocation.value,
        topLeadingOverlay: groupSelector,
        locationDetailBuilder:
            (location, onClose, {onPreviousLocation, onNextLocation}) {
              final matchingLocations = locations.value
                  .where((item) => _hasSameCoordinate(item, location))
                  .toList(growable: false);
              final tripIds = matchingLocations
                  .map((item) => item.tripId)
                  .toSet();
              final matchingTrips = trips.value
                  .where((trip) => tripIds.contains(trip.id))
                  .toList(growable: false);
              return MapPinBottomSheet(
                location: location,
                trips: matchingTrips,
                hasTripLoadError: hasTripLoadError.value,
                onTripTapped: handleTripTapped,
                onClose: onClose,
                onPreviousLocation: onPreviousLocation,
                onNextLocation: onNextLocation,
              );
            },
        locationDetailBottomSheetHeight: MapPinBottomSheet.height,
        isReadOnly: true,
      ),
    );

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Stack(
        children: [
          mapView,
          if (isGroupDataLoading.value)
            const Center(child: CircularProgressIndicator())
          else if (locations.value.isEmpty)
            const _NoVisitLocationsMessage(),
        ],
      ),
    );
  }
}

class _MapGroupSelector extends StatelessWidget {
  const _MapGroupSelector({
    required this.groups,
    required this.selectedGroup,
    required this.onSelected,
  });

  final List<GroupDto> groups;
  final GroupDto selectedGroup;
  final ValueChanged<GroupDto> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: PopupMenuButton<String>(
        key: const Key('map_group_selector'),
        tooltip: '表示するグループを選択',
        initialValue: selectedGroup.id,
        onSelected: (groupId) {
          onSelected(groups.firstWhere((group) => group.id == groupId));
        },
        itemBuilder: (context) {
          return [
            for (final group in groups)
              PopupMenuItem<String>(
                value: group.id,
                child: Text(group.name, overflow: TextOverflow.ellipsis),
              ),
          ];
        },
        child: Chip(
          visualDensity: VisualDensity.compact,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  selectedGroup.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoVisitLocationsMessage extends StatelessWidget {
  const _NoVisitLocationsMessage();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('このグループには訪問場所がありません'),
          ),
        ),
      ),
    );
  }
}

bool _hasSameCoordinate(LocationDto left, LocationDto right) {
  return left.latitude == right.latitude && left.longitude == right.longitude;
}
