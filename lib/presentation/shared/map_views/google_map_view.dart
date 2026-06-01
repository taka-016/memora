import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/notifiers/coordinate_notifier.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';

class GoogleMapView extends HookConsumerWidget {
  final List<LocationDto> locations;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final ValueChanged<LocationDto>? onLocationTapped;
  final LocationDto? selectedLocation;
  final bool highlightSelectedLocation;
  final DateTime? tripStartDate;
  final bool isReadOnly;

  const GoogleMapView({
    super.key,
    required this.locations,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onLocationTapped,
    this.selectedLocation,
    this.highlightSelectedLocation = false,
    this.tripStartDate,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fallbackPosition = LatLng(35.681236, 139.767125); // 東京駅

    final mapController = useState<GoogleMapController?>(null);
    final isBottomSheetVisible = useState(false);
    final selectedLocationState = useState<LocationDto?>(null);
    final previousSelectedLocation = useRef<LocationDto?>(null);

    void showErrorSnackBar(String message) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    void animateToPosition(LatLng position) {
      mapController.value?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 15),
        ),
      );
    }

    LatLng getCurrentOrFallbackPosition() {
      final selected = selectedLocation;
      if (selected != null) {
        return LatLng(selected.latitude, selected.longitude);
      }
      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        return LatLng(firstLocation.latitude, firstLocation.longitude);
      }
      final coordinate = ref.read(coordinateProvider).coordinate;
      return coordinate != null
          ? LatLng(coordinate.latitude, coordinate.longitude)
          : fallbackPosition;
    }

    Future<void> moveToCurrentLocation() async {
      try {
        await ref.read(coordinateProvider.notifier).getCurrentLocation();
        final coordinate = ref.read(coordinateProvider).coordinate;

        if (coordinate == null) {
          showErrorSnackBar('現在地が取得できませんでした');
          return;
        }

        animateToPosition(LatLng(coordinate.latitude, coordinate.longitude));
      } catch (e, stack) {
        logger.e(
          'GoogleMapView.moveToCurrentLocation: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        showErrorSnackBar('現在地取得に失敗: $e');
      }
    }

    Future<void> handleSearchedLocationSelected(
      LocationCandidateDto candidate,
    ) async {
      final coordinate = candidate.coordinate;
      animateToPosition(LatLng(coordinate.latitude, coordinate.longitude));
      onSearchedLocationSelected?.call(candidate);
    }

    void handleMapCreated(GoogleMapController controller) {
      mapController.value = controller;
    }

    void handleMapLongPress(LatLng position) {
      onMapLongTapped?.call(
        Coordinate(latitude: position.latitude, longitude: position.longitude),
      );
    }

    void hideLocationDetailBottomSheet() {
      isBottomSheetVisible.value = false;
      selectedLocationState.value = null;
    }

    void handleLocationTapped(LocationDto location) {
      onLocationTapped?.call(location);
      selectedLocationState.value = location;
      isBottomSheetVisible.value = true;
    }

    useEffect(() {
      if (selectedLocation != null &&
          selectedLocation != previousSelectedLocation.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleLocationTapped(selectedLocation!);
        });
      }
      previousSelectedLocation.value = selectedLocation;
      return null;
    }, [selectedLocation]);

    Set<Marker> buildLocations() {
      return locations
          .map(
            (location) => Marker(
              markerId: MarkerId(location.id),
              position: LatLng(location.latitude, location.longitude),
              icon:
                  !highlightSelectedLocation ||
                      selectedLocation?.id == location.id
                  ? BitmapDescriptor.defaultMarker
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
              onTap: () => handleLocationTapped(location),
            ),
          )
          .toSet();
    }

    Widget buildGoogleMap() {
      return GoogleMap(
        onMapCreated: handleMapCreated,
        initialCameraPosition: CameraPosition(
          target: getCurrentOrFallbackPosition(),
          zoom: 15,
        ),
        markers: buildLocations(),
        onLongPress: handleMapLongPress,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      );
    }

    Widget buildSearchBar() {
      return Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: CustomSearchBar(
          hintText: '場所を検索',
          onCandidateSelected: (candidate) async {
            await handleSearchedLocationSelected(candidate);
          },
        ),
      );
    }

    Widget buildLocationButton() {
      return Positioned(
        bottom: 180,
        right: 4,
        child: FloatingActionButton(
          heroTag: 'my_location_fab',
          onPressed: moveToCurrentLocation,
          child: const Icon(Icons.my_location),
        ),
      );
    }

    Widget buildBottomSheet() {
      if (!isBottomSheetVisible.value || selectedLocationState.value == null) {
        return const SizedBox.shrink();
      }

      return LocationDetailBottomSheet(
        location: selectedLocationState.value!,
        onClose: hideLocationDetailBottomSheet,
      );
    }

    return Container(
      key: const Key('map_view'),
      child: Stack(
        children: [
          buildGoogleMap(),
          buildSearchBar(),
          buildLocationButton(),
          buildBottomSheet(),
        ],
      ),
    );
  }
}
