import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';
import 'package:memora/presentation/notifiers/coordinate_notifier.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

class GoogleMapView extends HookConsumerWidget {
  final List<PinDto> pins;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final Function(PinDto)? onMarkerTapped;
  final Function(PinDto)? onMarkerUpdated;
  final Function(String)? onMarkerDeleted;
  final PinDto? selectedPin;
  final bool isReadOnly;
  final LocationSearchService? locationSearchService;

  const GoogleMapView({
    super.key,
    required this.pins,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onMarkerTapped,
    this.onMarkerUpdated,
    this.onMarkerDeleted,
    this.selectedPin,
    this.isReadOnly = false,
    this.locationSearchService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const fallbackPosition = LatLng(35.681236, 139.767125); // 東京駅

    final mapController = useState<GoogleMapController?>(null);
    final isBottomSheetVisible = useState(false);
    final selectedPinState = useState<PinDto?>(null);
    final previousSelectedPin = useRef<PinDto?>(null);

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
      if (pins.isNotEmpty) {
        final firstPin = pins.first;
        return LatLng(firstPin.latitude, firstPin.longitude);
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

    Future<void> moveToSearchedLocation(LocationCandidateDto candidate) async {
      final coordinate = candidate.coordinate;
      animateToPosition(LatLng(coordinate.latitude, coordinate.longitude));
      onSearchedLocationSelected?.call(candidate);
    }

    void onMapCreated(GoogleMapController controller) {
      mapController.value = controller;
    }

    void onMapLongTap(LatLng position) {
      onMapLongTapped?.call(
        Coordinate(latitude: position.latitude, longitude: position.longitude),
      );
    }

    void hidePinDetailBottomSheet() {
      isBottomSheetVisible.value = false;
      selectedPinState.value = null;
    }

    void onMarkerUpdate(PinDto pin) {
      onMarkerUpdated?.call(pin);
      hidePinDetailBottomSheet();
    }

    void onMarkerDelete(String pinId) {
      onMarkerDeleted?.call(pinId);
      hidePinDetailBottomSheet();
    }

    void onMarkerTap(PinDto pin) {
      onMarkerTapped?.call(pin);
      selectedPinState.value = pin;
      isBottomSheetVisible.value = true;
    }

    useEffect(() {
      if (selectedPin != null && selectedPin != previousSelectedPin.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onMarkerTap(selectedPin!);
        });
      }
      previousSelectedPin.value = selectedPin;
      return null;
    }, [selectedPin]);

    Set<Marker> buildMarkers() {
      return pins
          .map(
            (pin) => Marker(
              markerId: MarkerId(pin.pinId),
              position: LatLng(pin.latitude, pin.longitude),
              onTap: () => onMarkerTap(pin),
            ),
          )
          .toSet();
    }

    Widget buildGoogleMap() {
      return GoogleMap(
        onMapCreated: onMapCreated,
        initialCameraPosition: CameraPosition(
          target: getCurrentOrFallbackPosition(),
          zoom: 15,
        ),
        markers: buildMarkers(),
        onLongPress: onMapLongTap,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      );
    }

    Widget buildSearchBar() {
      final effectiveLocationSearchService =
          locationSearchService ??
          GooglePlacesApiLocationSearchService(apiKey: Env.googlePlacesApiKey);

      return Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: CustomSearchBar(
          hintText: '場所を検索',
          locationSearchService: effectiveLocationSearchService,
          onCandidateSelected: (candidate) async {
            await moveToSearchedLocation(candidate);
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
      if (!isBottomSheetVisible.value || selectedPinState.value == null) {
        return const SizedBox.shrink();
      }

      return PinDetailBottomSheet(
        pin: selectedPinState.value!,
        onUpdate: isReadOnly ? null : onMarkerUpdate,
        onDelete: isReadOnly ? null : onMarkerDelete,
        onClose: hidePinDetailBottomSheet,
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
