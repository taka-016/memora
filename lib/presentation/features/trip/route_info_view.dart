import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/constants/color_constants.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';
import 'package:memora/presentation/shared/sheets/route_memo_edit_bottom_sheet.dart';

part 'route_list.dart';
part 'route_map.dart';

const double _inactivePolylineOpacity = 0.4;

class RouteInfoViewTestHandle {
  Map<String, RouteSegmentDetail> Function()? _getSegmentDetails;
  int? Function()? _getSelectedPinIndex;
  Map<String, Color> Function()? _getSegmentHighlightColors;
  bool Function()? _getShouldFitMap;
  void Function(int index)? _selectPin;

  Map<String, RouteSegmentDetail> get segmentDetails =>
      _getSegmentDetails?.call() ?? const {};

  int? get selectedPinIndex => _getSelectedPinIndex?.call();

  Map<String, Color> get segmentHighlightColors =>
      _getSegmentHighlightColors?.call() ?? const {};

  bool get shouldFitMapToRoutesWhenVisible => _getShouldFitMap?.call() ?? false;

  void selectPinForTest(int index) {
    _selectPin?.call(index);
  }
}

class RouteInfoView extends HookWidget {
  const RouteInfoView({
    super.key,
    required this.pins,
    this.routeInfoService,
    this.onClose,
    this.isTestEnvironment = false,
    this.testHandle,
  });

  final List<PinDto> pins;
  final RouteInfoService? routeInfoService;
  final VoidCallback? onClose;
  final bool isTestEnvironment;
  final RouteInfoViewTestHandle? testHandle;

  @override
  Widget build(BuildContext context) {
    final service =
        routeInfoService ??
        GoogleRoutesApiRouteInfoService(apiKey: Env.googlePlacesApiKey);

    final pinsState = useState<List<PinDto>>(List<PinDto>.from(pins));
    final segmentModesState = useState<Map<String, TravelMode>>({});
    final segmentDetailsState = useState<Map<String, RouteSegmentDetail>>({});
    final routeMemoExpansionState = useState<Map<String, bool>>({});
    final isLoadingState = useState(false);
    final errorMessageState = useState<String?>(null);
    final isMapVisibleState = useState(true);
    final selectedPinIndexState = useState<int?>(null);
    final mapControllerState = useState<GoogleMapController?>(null);
    final shouldFitMapState = useState(false);

    String segmentKey(PinDto origin, PinDto destination) {
      return '${origin.pinId}->${destination.pinId}';
    }

    void cleanupSegmentDetails(Iterable<String> validKeys) {
      final validKeySet = validKeys.toSet();
      segmentDetailsState.value = Map<String, RouteSegmentDetail>.from(
        segmentDetailsState.value,
      )..removeWhere((key, _) => !validKeySet.contains(key));
    }

    Map<String, TravelMode> buildSegmentModes(
      Map<String, TravelMode> previous,
    ) {
      final map = <String, TravelMode>{};
      final validKeys = <String>[];
      final currentPins = pinsState.value;
      for (var i = 0; i < currentPins.length - 1; i++) {
        final key = segmentKey(currentPins[i], currentPins[i + 1]);
        validKeys.add(key);
        map[key] = previous[key] ?? TravelMode.drive;
      }
      cleanupSegmentDetails(validKeys);
      return map;
    }

    RouteSegmentDetail sanitizeManualDetail(RouteSegmentDetail detail) {
      final sanitizedInstructions = detail.instructions
          .map((instruction) => instruction.trim())
          .where((instruction) => instruction.isNotEmpty)
          .toList();
      final sanitizedDuration = detail.durationSeconds > 0
          ? detail.durationSeconds
          : 0;
      return detail.copyWith(
        durationSeconds: sanitizedDuration,
        instructions: sanitizedInstructions,
      );
    }

    bool hasManualContent(RouteSegmentDetail detail) {
      return detail.instructions.isNotEmpty || detail.durationSeconds > 0;
    }

    void scheduleManualRouteUpdate(String key, RouteSegmentDetail detail) {
      final normalized = sanitizeManualDetail(detail);

      void applyUpdate() {
        if (!context.mounted) {
          return;
        }
        final current = segmentDetailsState.value[key];
        final updated = Map<String, RouteSegmentDetail>.from(
          segmentDetailsState.value,
        );
        if (hasManualContent(normalized)) {
          if (current == null) {
            updated[key] = normalized;
          } else {
            updated[key] = current.copyWith(
              durationSeconds: normalized.durationSeconds,
              instructions: normalized.instructions,
            );
          }
        } else if (current != null) {
          updated[key] = current.copyWith(
            durationSeconds: 0,
            instructions: const [],
          );
        }
        segmentDetailsState.value = updated;
      }

      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle ||
          phase == SchedulerPhase.postFrameCallbacks) {
        applyUpdate();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      }
    }

    Future<void> openOtherRouteInfoSheet(String key) async {
      final initialDetail =
          segmentDetailsState.value[key] ?? const RouteSegmentDetail.empty();

      final result = await showModalBottomSheet<RouteSegmentDetail>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return RouteMemoEditBottomSheet(
            initialDetail: initialDetail,
            onChanged: (value) => scheduleManualRouteUpdate(key, value),
          );
        },
      );

      if (!context.mounted) {
        return;
      }

      if (result != null) {
        scheduleManualRouteUpdate(key, result);
      }
    }

    RouteSegmentDetail mergeRouteDetailForMode({
      required String key,
      required TravelMode mode,
      required RouteSegmentDetail fetchedDetail,
    }) {
      if (mode != TravelMode.other) {
        return fetchedDetail;
      }
      final existingDetail = segmentDetailsState.value[key];
      if (existingDetail == null || !hasManualContent(existingDetail)) {
        return fetchedDetail;
      }
      final updatedPolyline = fetchedDetail.polyline.isNotEmpty
          ? fetchedDetail.polyline
          : existingDetail.polyline;
      return existingDetail.copyWith(polyline: updatedPolyline);
    }

    Future<void> fitMapToRoutes() async {
      final controller = mapControllerState.value;
      if (segmentDetailsState.value.isEmpty || controller == null) {
        return;
      }
      final points = segmentDetailsState.value.values
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
      if (segmentDetailsState.value.isEmpty) {
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

    Map<String, RouteSegmentDetail> retainManualDetails(
      Map<String, RouteSegmentDetail> previousDetails,
      Map<String, TravelMode> nextModes,
    ) {
      final retained = <String, RouteSegmentDetail>{};
      for (final entry in nextModes.entries) {
        if (entry.value != TravelMode.other) {
          continue;
        }
        final detail = previousDetails[entry.key];
        if (detail == null || !hasManualContent(detail)) {
          continue;
        }
        retained[entry.key] = detail;
      }
      return retained;
    }

    Future<void> searchRoutes() async {
      if (pinsState.value.length < 2) {
        return;
      }

      isLoadingState.value = true;
      errorMessageState.value = null;

      final nextResults = <String, RouteSegmentDetail>{};

      try {
        final currentPins = pinsState.value;
        for (var i = 0; i < currentPins.length - 1; i++) {
          final origin = currentPins[i];
          final destination = currentPins[i + 1];
          final key = segmentKey(origin, destination);
          final mode = segmentModesState.value[key] ?? TravelMode.drive;

          RouteSegmentDetail detail = await service.fetchRoute(
            origin: Location(
              latitude: origin.latitude,
              longitude: origin.longitude,
            ),
            destination: Location(
              latitude: destination.latitude,
              longitude: destination.longitude,
            ),
            travelMode: mode,
          );
          detail = mergeRouteDetailForMode(
            key: key,
            mode: mode,
            fetchedDetail: detail,
          );

          nextResults[key] = detail;
        }

        if (!context.mounted) {
          return;
        }
        segmentDetailsState.value = nextResults;
        routeMemoExpansionState.value = {
          for (final entry in nextResults.entries) entry.key: false,
        };
        await handleFitMapToRoutesRequest();
      } catch (e, stackTrace) {
        logger.e(
          'RouteInfoView.searchRoutes: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        );
        if (!context.mounted) {
          return;
        }
        errorMessageState.value = '経路の取得に失敗しました: $e';
      } finally {
        if (context.mounted) {
          isLoadingState.value = false;
        }
      }
    }

    void onReorder(int oldIndex, int newIndex) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updatedPins = List<PinDto>.from(pinsState.value);
      final previousDetails = Map<String, RouteSegmentDetail>.from(
        segmentDetailsState.value,
      );
      final item = updatedPins.removeAt(oldIndex);
      updatedPins.insert(newIndex, item);
      pinsState.value = updatedPins;
      final nextModes = buildSegmentModes(segmentModesState.value);
      segmentModesState.value = nextModes;
      segmentDetailsState.value = retainManualDetails(
        previousDetails,
        nextModes,
      );
      routeMemoExpansionState.value = {};
      selectedPinIndexState.value = null;
    }

    void onModeChanged(String key, TravelMode mode) {
      final previousMode = segmentModesState.value[key];
      if (previousMode == mode) {
        return;
      }
      segmentModesState.value = {...segmentModesState.value, key: mode};
      if (mode == TravelMode.other || previousMode == TravelMode.other) {
        final updated = Map<String, RouteSegmentDetail>.from(
          segmentDetailsState.value,
        )..remove(key);
        segmentDetailsState.value = updated;
      }
    }

    void toggleRouteMemoExpansion(String key) {
      final current = routeMemoExpansionState.value[key] ?? false;
      routeMemoExpansionState.value = {
        ...routeMemoExpansionState.value,
        key: !current,
      };
    }

    Set<String> activeSegmentKeys() {
      if (selectedPinIndexState.value == null) {
        return segmentDetailsState.value.keys.toSet();
      }
      final set = <String>{};
      final index = selectedPinIndexState.value!;
      if (index - 1 >= 0) {
        set.add(segmentKey(pinsState.value[index - 1], pinsState.value[index]));
      }
      if (index + 1 < pinsState.value.length) {
        set.add(segmentKey(pinsState.value[index], pinsState.value[index + 1]));
      }
      return set;
    }

    void onPinTap(int index) {
      if (selectedPinIndexState.value == index) {
        selectedPinIndexState.value = null;
      } else {
        selectedPinIndexState.value = index;
      }
    }

    void toggleMapVisibility() {
      final nextVisibility = !isMapVisibleState.value;
      isMapVisibleState.value = nextVisibility;
      if (!nextVisibility) {
        mapControllerState.value?.dispose();
        mapControllerState.value = null;
        if (segmentDetailsState.value.isNotEmpty) {
          shouldFitMapState.value = true;
        }
      } else {
        scheduleFitMapCameraUpdate();
      }
    }

    LatLng initialCameraPosition() {
      if (pinsState.value.isNotEmpty) {
        final pin = pinsState.value.first;
        return LatLng(pin.latitude, pin.longitude);
      }
      return const LatLng(35.681236, 139.767125);
    }

    Set<Marker> buildMarkers() {
      return pinsState.value
          .map(
            (pin) => Marker(
              markerId: MarkerId(pin.pinId),
              position: LatLng(pin.latitude, pin.longitude),
              infoWindow: InfoWindow(title: pin.locationName ?? ''),
            ),
          )
          .toSet();
    }

    Color colorForPolylineIndex(int index, bool isActive) {
      if (isActive) {
        return ColorConstants.getSequentialColor(index);
      }
      return ColorConstants.getSequentialColorWithOpacity(
        index,
        _inactivePolylineOpacity,
      );
    }

    Set<Polyline> createPolylines() {
      final polylines = <Polyline>{};
      final activeKeys = activeSegmentKeys();
      final keys = segmentDetailsState.value.keys.toList();

      for (var i = 0; i < keys.length; i++) {
        final key = keys[i];
        final detail = segmentDetailsState.value[key];
        if (detail == null || detail.polyline.isEmpty) {
          continue;
        }
        final isActive = activeKeys.contains(key);
        final color = colorForPolylineIndex(i, isActive);
        polylines.add(
          Polyline(
            polylineId: PolylineId(key),
            points: detail.polyline
                .map(
                  (location) => LatLng(location.latitude, location.longitude),
                )
                .toList(),
            color: color,
            width: isActive ? 6 : 4,
          ),
        );
      }

      return polylines;
    }

    Map<String, Color> computeSegmentHighlightColors() {
      final colors = <String, Color>{};
      for (final polyline in createPolylines()) {
        colors[polyline.polylineId.value] = polyline.color;
      }
      return colors;
    }

    void handleClose() {
      if (onClose != null) {
        onClose!();
        return;
      }
      Navigator.of(context).maybePop();
    }

    Widget buildHeader() {
      return Row(
        children: [
          const Text(
            '経路情報',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(onPressed: handleClose, icon: const Icon(Icons.close)),
        ],
      );
    }

    Widget buildActionRow() {
      return Row(
        children: [
          ElevatedButton(
            onPressed: isLoadingState.value ? null : searchRoutes,
            child: isLoadingState.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('経路検索'),
          ),
        ],
      );
    }

    Widget buildErrorBanner() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          errorMessageState.value!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
        ),
      );
    }

    Widget buildMapSection() {
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
            target: initialCameraPosition(),
            zoom: 12,
          ),
          polylines: createPolylines(),
          markers: buildMarkers(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      );
    }

    useEffect(() {
      segmentModesState.value = buildSegmentModes({});
      return null;
    }, []);

    useEffect(() {
      return () {
        mapControllerState.value?.dispose();
      };
    }, []);

    useEffect(() {
      if (testHandle == null) {
        return null;
      }
      final handle = testHandle!;
      handle._getSegmentDetails = () =>
          Map<String, RouteSegmentDetail>.unmodifiable(
            segmentDetailsState.value,
          );
      handle._getSelectedPinIndex = () => selectedPinIndexState.value;
      handle._getSegmentHighlightColors = () => computeSegmentHighlightColors();
      handle._getShouldFitMap = () => shouldFitMapState.value;
      handle._selectPin = (index) {
        if (index < 0 || index >= pinsState.value.length) {
          return;
        }
        selectedPinIndexState.value = index;
      };
      return () {
        if (testHandle == null) {
          return;
        }
        handle
          .._getSegmentDetails = null
          .._getSelectedPinIndex = null
          .._getSegmentHighlightColors = null
          .._getShouldFitMap = null
          .._selectPin = null;
      };
    }, [testHandle]);

    return SizedBox(
      key: const Key('route_info_view_root'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 16),
          buildActionRow(),
          if (errorMessageState.value != null) ...[
            const SizedBox(height: 12),
            buildErrorBanner(),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: RouteListSection(
                    pins: pinsState.value,
                    segmentModes: segmentModesState.value,
                    segmentDetails: segmentDetailsState.value,
                    routeMemoExpansion: routeMemoExpansionState.value,
                    selectedPinIndex: selectedPinIndexState.value,
                    onReorder: onReorder,
                    onPinTap: onPinTap,
                    onModeChanged: onModeChanged,
                    onToggleRouteMemo: toggleRouteMemoExpansion,
                    onOpenOtherRouteInfoSheet: openOtherRouteInfoSheet,
                    segmentKeyBuilder: segmentKey,
                  ),
                ),
                RouteMapSection(
                  isMapVisible: isMapVisibleState.value,
                  isTestEnvironment: isTestEnvironment,
                  onToggleVisibility: toggleMapVisibility,
                  mapBuilder: (_) => buildMapSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
