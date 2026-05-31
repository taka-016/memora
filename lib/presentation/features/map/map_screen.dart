import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/usecases/trip/get_locations_by_member_id_usecase.dart';
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

    final getLocationsByMemberIdUsecase = useMemoized(
      () => ref.read(getLocationsByMemberIdUsecaseProvider),
    );
    final locations = useState<List<LocationDto>>([]);

    useEffect(() {
      Future.microtask(() async {
        locations.value = await getLocationsByMemberIdUsecase.execute(
          currentMember.id,
        );
      });
      return null;
    }, [getLocationsByMemberIdUsecase, currentMember.id]);

    final mapViewType = isTestEnvironment
        ? MapViewType.placeholder
        : MapViewType.google;
    final pins = locations.value.map(_locationToPin).toList();

    return MapViewFactory.create(
      mapViewType,
    ).createMapView(pins: pins, isReadOnly: true);
  }

  PinDto _locationToPin(LocationDto location) {
    return PinDto(
      pinId: location.id,
      tripId: location.tripId,
      groupId: location.groupId,
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.name,
    );
  }
}
