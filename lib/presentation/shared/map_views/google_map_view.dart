import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';

class GoogleMapView extends HookConsumerWidget {
  final List<LocationDto> locations;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final ValueChanged<LocationDto>? onLocationTapped;
  final LocationDto? selectedLocation;
  final LocationDto? focusedLocation;
  final bool highlightSelectedLocation;
  final LocationDetailBuilder? locationDetailBuilder;
  final double? locationDetailBottomSheetHeight;
  final DateTime? tripStartDate;
  final bool isReadOnly;

  const GoogleMapView({
    super.key,
    required this.locations,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onLocationTapped,
    this.selectedLocation,
    this.focusedLocation,
    this.highlightSelectedLocation = false,
    this.locationDetailBuilder,
    this.locationDetailBottomSheetHeight,
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
    final previousFocusedLocation = useRef<LocationDto?>(null);
    final grayMarkerIcon = useFuture(
      useMemoized(() => createGrayMarkerIcon(), const []),
    );

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
      final focused = focusedLocation;
      if (focused != null) {
        return LatLng(focused.latitude, focused.longitude);
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
      final initialSelectedLocation =
          selectedLocationState.value ?? selectedLocation ?? focusedLocation;
      if (initialSelectedLocation != null) {
        animateToPosition(
          LatLng(
            initialSelectedLocation.latitude,
            initialSelectedLocation.longitude,
          ),
        );
      }
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

    void moveSelectedLocationBy(int offset) {
      final current = selectedLocationState.value;
      final navigationLocations = _uniqueLocationsByCoordinate(locations);
      if (current == null || navigationLocations.length < 2) {
        return;
      }

      final currentIndex = navigationLocations.indexWhere(
        (location) => _hasSameCoordinate(location, current),
      );
      if (currentIndex == -1) {
        return;
      }

      final nextIndex = (currentIndex + offset) % navigationLocations.length;
      final nextLocation =
          navigationLocations[nextIndex < 0
              ? nextIndex + navigationLocations.length
              : nextIndex];
      handleLocationTapped(nextLocation);
      animateToPosition(LatLng(nextLocation.latitude, nextLocation.longitude));
    }

    void moveToPreviousLocation() => moveSelectedLocationBy(-1);

    void moveToNextLocation() => moveSelectedLocationBy(1);

    useEffect(() {
      if (focusedLocation != null &&
          focusedLocation != previousFocusedLocation.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final location = focusedLocation!;
          animateToPosition(LatLng(location.latitude, location.longitude));
        });
      }
      previousFocusedLocation.value = focusedLocation;
      return null;
    }, [focusedLocation]);

    useEffect(() {
      if (selectedLocation != null &&
          selectedLocation != previousSelectedLocation.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final location = selectedLocation!;
          handleLocationTapped(location);
          animateToPosition(LatLng(location.latitude, location.longitude));
        });
      }
      previousSelectedLocation.value = selectedLocation;
      return null;
    }, [selectedLocation]);

    Set<Marker> buildLocations() {
      return _uniqueLocationsByCoordinate(locations)
          .map(
            (location) => Marker(
              markerId: MarkerId(location.id),
              position: LatLng(location.latitude, location.longitude),
              icon: markerIconFor(
                location: location,
                grayMarkerIcon: grayMarkerIcon.data,
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
      final bottomOffset = isBottomSheetVisible.value
          ? (locationDetailBottomSheetHeight ?? 160) + 20
          : 20.0;

      return Positioned(
        bottom: bottomOffset,
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

      final navigationLocations = _uniqueLocationsByCoordinate(locations);
      final hasMultipleNavigationTargets = navigationLocations.length >= 2;
      final detailBuilder = locationDetailBuilder;
      if (detailBuilder != null) {
        return detailBuilder(
          selectedLocationState.value!,
          hideLocationDetailBottomSheet,
          onPreviousLocation: hasMultipleNavigationTargets
              ? moveToPreviousLocation
              : null,
          onNextLocation: hasMultipleNavigationTargets
              ? moveToNextLocation
              : null,
        );
      }

      return LocationDetailBottomSheet(
        location: selectedLocationState.value!,
        onClose: hideLocationDetailBottomSheet,
        height: locationDetailBottomSheetHeight,
        onPreviousLocation: hasMultipleNavigationTargets
            ? moveToPreviousLocation
            : null,
        onNextLocation: hasMultipleNavigationTargets
            ? moveToNextLocation
            : null,
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

  BitmapDescriptor markerIconFor({
    required LocationDto location,
    required BitmapDescriptor? grayMarkerIcon,
  }) {
    if (!highlightSelectedLocation || selectedLocation?.id == location.id) {
      return BitmapDescriptor.defaultMarker;
    }
    return grayMarkerIcon ?? grayLocationMarkerIcon;
  }
}

List<LocationDto> _uniqueLocationsByCoordinate(List<LocationDto> locations) {
  final uniqueLocations = <LocationDto>[];
  final coordinateKeys = <String>{};

  for (final location in locations) {
    final key = '${location.latitude},${location.longitude}';
    if (coordinateKeys.add(key)) {
      uniqueLocations.add(location);
    }
  }

  return uniqueLocations;
}

bool _hasSameCoordinate(LocationDto left, LocationDto right) {
  return left.latitude == right.latitude && left.longitude == right.longitude;
}

final grayLocationMarkerIcon = BitmapDescriptor.bytes(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAALElEQVR4nO3OoQEAAAwCIJ/2/u0MC4FO2t5SBAQEBAQEBAQEBAQEBAQE1oEHzUh4iPhXaT4AAAAASUVORK5CYII=',
  ),
  width: 32,
  height: 32,
);

Future<BitmapDescriptor> createGrayMarkerIcon() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fillPaint = Paint()..color = Colors.grey.shade600;
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final path = Path()
    ..moveTo(24, 46)
    ..cubicTo(19, 37, 10, 30, 10, 20)
    ..cubicTo(10, 10, 16, 4, 24, 4)
    ..cubicTo(32, 4, 38, 10, 38, 20)
    ..cubicTo(38, 30, 29, 37, 24, 46)
    ..close();
  canvas.drawPath(path, fillPaint);
  canvas.drawPath(path, borderPaint);
  canvas.drawCircle(const Offset(24, 20), 6, Paint()..color = Colors.white);

  final image = await recorder.endRecording().toImage(48, 48);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    Uint8List.view(byteData!.buffer),
    width: 32,
    height: 32,
  );
}
