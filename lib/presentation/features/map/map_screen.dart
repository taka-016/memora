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
    final selectedLocation = useState<LocationDto?>(null);
    final hasSelectedInitialLocation = useRef(false);

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
          locations.value = fetchedLocations;
          if (!hasSelectedInitialLocation.value &&
              fetchedLocations.isNotEmpty) {
            selectedLocation.value = fetchedLocations.first;
            hasSelectedInitialLocation.value = true;
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
      selectedLocation: selectedLocation.value,
      locationDetailBottomSheetHeight: 160,
      isReadOnly: true,
    );
  }
}
