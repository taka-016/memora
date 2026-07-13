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
      () => ref.read(getTripEntriesUsecaseProvider),
    );
    final getTripEntryByIdUsecase = useMemoized(
      () => ref.read(getTripEntryByIdUsecaseProvider),
    );
    final updateTripEntryUsecase = useMemoized(
      () => ref.read(updateTripEntryUsecaseProvider),
    );
    final groups = useState<List<GroupDto>>([]);
    final locations = useState<List<LocationDto>>([]);
    final trips = useState<List<TripEntryDto>>([]);
    final hasTripLoadError = useState(false);
    final focusedLocation = useState<LocationDto?>(null);
    final hasFocusedInitialLocation = useRef(false);

    useEffect(
      () {
        Future.microtask(() async {
          final fetchedGroups = await getGroupsWithMembersUsecase.execute(
            currentMember,
          );
          groups.value = fetchedGroups;
          final locationLists = await Future.wait(
            fetchedGroups.map(
              (group) => getLocationsByGroupIdUsecase.execute(group.id),
            ),
          );
          final fetchedLocations = [
            for (final groupLocations in locationLists) ...groupLocations,
          ];
          locations.value = fetchedLocations;

          var tripLoadFailed = false;
          final tripLists = await Future.wait(
            fetchedGroups.map((group) async {
              try {
                return await getTripEntriesUsecase.executeByGroupId(group.id);
              } catch (e, stack) {
                tripLoadFailed = true;
                logger.e(
                  'MapScreen.loadTrips: ${e.toString()}',
                  error: e,
                  stackTrace: stack,
                );
                return <TripEntryDto>[];
              }
            }),
          );
          trips.value = [for (final groupTrips in tripLists) ...groupTrips];
          hasTripLoadError.value = tripLoadFailed;

          if (!hasFocusedInitialLocation.value && fetchedLocations.isNotEmpty) {
            focusedLocation.value = fetchedLocations.first;
            hasFocusedInitialLocation.value = true;
          }
        });
        return null;
      },
      [
        getGroupsWithMembersUsecase,
        getLocationsByGroupIdUsecase,
        getTripEntriesUsecase,
        currentMember,
      ],
    );

    Future<void> handleTripTapped(TripEntryDto trip) async {
      try {
        final currentTrip = await getTripEntryByIdUsecase.execute(trip.id);
        if (!context.mounted) {
          return;
        }
        final group = groups.value
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

    return MapViewFactory.create(mapViewType).createMapView(
      locations: locations.value,
      focusedLocation: focusedLocation.value,
      locationDetailBuilder:
          (location, onClose, {onPreviousLocation, onNextLocation}) {
            final tripIds = locations.value
                .where((item) => _hasSameCoordinate(item, location))
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
    );
  }
}

bool _hasSameCoordinate(LocationDto left, LocationDto right) {
  return left.latitude == right.latitude && left.longitude == right.longitude;
}
