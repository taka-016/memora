part of 'route_info_view.dart';

class RouteMap extends HookWidget {
  const RouteMap({
    super.key,
    required this.pinsState,
    required this.segmentDetailsState,
    required this.selectedPinIndexState,
    required this.isMapVisibleState,
    required this.mapControllerState,
    required this.shouldFitMapState,
    required this.isTestEnvironment,
  });

  final ValueNotifier<List<PinDto>> pinsState;
  final ValueNotifier<Map<String, RouteSegmentDetail>> segmentDetailsState;
  final ValueNotifier<int?> selectedPinIndexState;
  final ValueNotifier<bool> isMapVisibleState;
  final ValueNotifier<GoogleMapController?> mapControllerState;
  final ValueNotifier<bool> shouldFitMapState;
  final bool isTestEnvironment;

  @override
  Widget build(BuildContext context) {
    useListenable(pinsState);
    useListenable(segmentDetailsState);
    useListenable(selectedPinIndexState);
    useListenable(isMapVisibleState);
    useListenable(mapControllerState);
    useListenable(shouldFitMapState);

    final pins = pinsState.value;
    final segmentDetails = segmentDetailsState.value;
    final selectedPinIndex = selectedPinIndexState.value;
    final isMapVisible = isMapVisibleState.value;

    Future<void> fitMapToRoutes() async {
      final controller = mapControllerState.value;
      if (segmentDetails.isEmpty || controller == null) {
        return;
      }
      final points = segmentDetails.values
          .expand((value) => value.polyline)
          .toList();
      if (points.isEmpty) {
        return;
      }

      double? south;
      double? west;
      double? north;
      double? east;

      for (final point in points) {
        south = south == null
            ? point.latitude
            : (south < point.latitude ? south : point.latitude);
        north = north == null
            ? point.latitude
            : (north > point.latitude ? north : point.latitude);
        west = west == null
            ? point.longitude
            : (west < point.longitude ? west : point.longitude);
        east = east == null
            ? point.longitude
            : (east > point.longitude ? east : point.longitude);
      }

      if (south == null || north == null || west == null || east == null) {
        return;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      );

      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }

    Future<void> handleFitMapToRoutesRequest() async {
      if (segmentDetails.isEmpty) {
        shouldFitMapState.value = false;
        return;
      }

      if (isTestEnvironment) {
        shouldFitMapState.value = !isMapVisibleState.value;
        return;
      }

      final controller = mapControllerState.value;
      if (!isMapVisibleState.value || controller == null) {
        shouldFitMapState.value = true;
        return;
      }

      shouldFitMapState.value = false;
      await fitMapToRoutes();
    }

    void scheduleFitMapCameraUpdate() {
      if (!context.mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(handleFitMapToRoutesRequest());
      });
    }

    useEffect(() {
      if (shouldFitMapState.value) {
        scheduleFitMapCameraUpdate();
      }
      return null;
    }, [shouldFitMapState.value]);

    void toggleMapVisibility() {
      final nextVisibility = !isMapVisibleState.value;
      isMapVisibleState.value = nextVisibility;
      if (!nextVisibility) {
        mapControllerState.value?.dispose();
        mapControllerState.value = null;
        if (segmentDetails.isNotEmpty) {
          shouldFitMapState.value = true;
        }
      } else {
        scheduleFitMapCameraUpdate();
      }
    }

    return AnimatedContainer(
      key: const Key('route_info_map_area'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: isMapVisible ? _expandedHeight(context) : 56.0,
      child: Column(
        children: [
          _buildMapToggleButton(isMapVisible, toggleMapVisibility),
          if (isMapVisible)
            Expanded(
              child: _buildMapView(
                context,
                pins,
                segmentDetails,
                selectedPinIndex,
                scheduleFitMapCameraUpdate,
              ),
            ),
        ],
      ),
    );
  }

  double _expandedHeight(BuildContext context) {
    if (isTestEnvironment) {
      return 200.0;
    }
    final height = MediaQuery.of(context).size.height * 0.32;
    return height.clamp(180.0, 320.0);
  }

  Widget _buildMapToggleButton(
    bool isMapVisible,
    VoidCallback onToggleVisibility,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('route_info_map_toggle'),
        onPressed: onToggleVisibility,
        icon: Icon(isMapVisible ? Icons.remove : Icons.add),
        label: Text(isMapVisible ? 'マップ非表示' : 'マップ表示'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }

  Widget _buildMapView(
    BuildContext context,
    List<PinDto> pins,
    Map<String, RouteSegmentDetail> segmentDetails,
    int? selectedPinIndex,
    VoidCallback scheduleFitMapCameraUpdate,
  ) {
    if (isTestEnvironment) {
      return Container(
        key: const Key('route_info_map'),
        child: const Center(child: Text('マッププレビュー')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GoogleMap(
        key: const Key('route_info_map'),
        onMapCreated: (controller) {
          mapControllerState.value?.dispose();
          mapControllerState.value = controller;
          if (shouldFitMapState.value) {
            scheduleFitMapCameraUpdate();
          }
        },
        initialCameraPosition: CameraPosition(
          target: pins.isNotEmpty
              ? LatLng(pins.first.latitude, pins.first.longitude)
              : const LatLng(35.681236, 139.767125),
          zoom: 12,
        ),
        polylines: _buildRoutePolylines(
          segmentDetails: segmentDetails,
          pins: pins,
          selectedPinIndex: selectedPinIndex,
        ),
        markers: _buildMarkers(pins),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }

  Set<Marker> _buildMarkers(List<PinDto> pins) {
    return pins
        .map(
          (pin) => Marker(
            markerId: MarkerId(pin.pinId),
            position: LatLng(pin.latitude, pin.longitude),
            infoWindow: InfoWindow(title: pin.locationName ?? ''),
          ),
        )
        .toSet();
  }
}

Set<Polyline> _buildRoutePolylines({
  required Map<String, RouteSegmentDetail> segmentDetails,
  required List<PinDto> pins,
  required int? selectedPinIndex,
}) {
  final polylines = <Polyline>{};
  final activeKeys = _activeSegmentKeys(pins, selectedPinIndex);
  final keys = segmentDetails.keys.toList();

  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final detail = segmentDetails[key];
    if (detail == null || detail.polyline.isEmpty) {
      continue;
    }
    final isActive = activeKeys.contains(key);
    final color = _colorForPolylineIndex(i, isActive);
    polylines.add(
      Polyline(
        polylineId: PolylineId(key),
        points: detail.polyline
            .map((location) => LatLng(location.latitude, location.longitude))
            .toList(),
        color: color,
        width: isActive ? 6 : 4,
      ),
    );
  }

  return polylines;
}

Map<String, Color> _computeSegmentHighlightColors({
  required Map<String, RouteSegmentDetail> segmentDetails,
  required List<PinDto> pins,
  required int? selectedPinIndex,
}) {
  final colors = <String, Color>{};
  for (final polyline in _buildRoutePolylines(
    segmentDetails: segmentDetails,
    pins: pins,
    selectedPinIndex: selectedPinIndex,
  )) {
    colors[polyline.polylineId.value] = polyline.color;
  }
  return colors;
}

Set<String> _activeSegmentKeys(List<PinDto> pins, int? selectedPinIndex) {
  if (selectedPinIndex == null) {
    final keys = <String>{};
    for (var i = 0; i < pins.length - 1; i++) {
      keys.add(_routeSegmentKey(pins[i], pins[i + 1]));
    }
    return keys;
  }
  final set = <String>{};
  final index = selectedPinIndex;
  if (index - 1 >= 0) {
    set.add(_routeSegmentKey(pins[index - 1], pins[index]));
  }
  if (index + 1 < pins.length) {
    set.add(_routeSegmentKey(pins[index], pins[index + 1]));
  }
  return set;
}

Color _colorForPolylineIndex(int index, bool isActive) {
  if (isActive) {
    return ColorConstants.getSequentialColor(index);
  }
  return ColorConstants.getSequentialColorWithOpacity(
    index,
    _inactivePolylineOpacity,
  );
}
