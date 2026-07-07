import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
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
    final locations = useState<List<LocationDto>>([]);
    final focusedLocation = useState<LocationDto?>(null);
    final hasFocusedInitialLocation = useRef(false);

    useEffect(
      () {
        Future.microtask(() async {
          final groups = await getGroupsWithMembersUsecase.execute(
            currentMember,
          );
          final locationLists = await Future.wait(
            groups.map(
              (group) => getLocationsByGroupIdUsecase.execute(group.id),
            ),
          );
          final fetchedLocations = [
            for (final groupLocations in locationLists) ...groupLocations,
          ];
          final mergedLocations = mergeLocationsByCoordinate(fetchedLocations);
          locations.value = mergedLocations;
          if (!hasFocusedInitialLocation.value && mergedLocations.isNotEmpty) {
            focusedLocation.value = mergedLocations.first;
            hasFocusedInitialLocation.value = true;
          }
        });
        return null;
      },
      [
        getGroupsWithMembersUsecase,
        getLocationsByGroupIdUsecase,
        currentMember,
      ],
    );

    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;

    return MapViewFactory.create(mapViewType).createMapView(
      locations: locations.value,
      focusedLocation: focusedLocation.value,
      locationDetailBottomSheetHeight: 160,
      isReadOnly: true,
    );
  }
}

List<LocationDto> mergeLocationsByCoordinate(List<LocationDto> locations) {
  final mergedLocations = <LocationDto>[];
  final coordinateKeys = <String>{};

  for (final location in locations) {
    final key = '${location.latitude},${location.longitude}';
    if (coordinateKeys.add(key)) {
      mergedLocations.add(location);
    }
  }

  return mergedLocations;
}
