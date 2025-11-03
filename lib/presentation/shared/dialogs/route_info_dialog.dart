import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_information_service.dart';
import 'package:memora/presentation/shared/dialogs/route_info_dialog_controller.dart';

class RouteInfoDialog extends StatefulWidget {
  final List<PinDto> pins;
  final RouteInformationService? routeInformationService;
  final bool isTestEnvironment;
  final DateTime Function()? nowProvider;
  @visibleForTesting
  final void Function(RouteInfoDialogController controller)? onControllerReady;

  const RouteInfoDialog({
    super.key,
    required this.pins,
    this.routeInformationService,
    this.isTestEnvironment = false,
    this.nowProvider,
    this.onControllerReady,
  });

  @override
  State<RouteInfoDialog> createState() => _RouteInfoDialogState();
}

class _RouteInfoDialogState extends State<RouteInfoDialog> {
  late final RouteInformationService _routeInformationService;
  late final RouteInfoDialogController _controller;
  GoogleMapController? _mapController;
  bool _isMapVisible = true;

  @override
  void initState() {
    super.initState();
    _routeInformationService =
        widget.routeInformationService ??
        GoogleRoutesApiRouteInformationService(apiKey: Env.googlePlacesApiKey);
    _controller = RouteInfoDialogController(
      pins: widget.pins,
      routeInformationService: _routeInformationService,
      nowProvider: widget.nowProvider,
    )..addListener(_handleControllerChanged);
    widget.onControllerReady?.call(_controller);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (widget.isTestEnvironment) {
      return;
    }
    _updateCameraForSelectedSegment();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildSearchControls(),
              const SizedBox(height: 12),
              Expanded(child: _buildPinsAndSegments()),
              const SizedBox(height: 12),
              _buildMapSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '経路情報',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchControls() {
    return Row(
      children: [
        ElevatedButton(
          key: const Key('route_search_button'),
          onPressed: _controller.isLoading ? null : _controller.searchRoutes,
          style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
          child: _controller.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('経路検索'),
        ),
        const SizedBox(width: 16),
        if (_controller.isLoading) const Text('経路情報を取得中です...'),
      ],
    );
  }

  Widget _buildPinsAndSegments() {
    if (_controller.pins.isEmpty) {
      return const Center(child: Text('訪問場所が登録されていません。'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controller.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _controller.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: ReorderableListView(
            key: const Key('route_pin_reorder_list'),
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            onReorder: (oldIndex, newIndex) =>
                _controller.reorderPins(oldIndex: oldIndex, newIndex: newIndex),
            children: List.generate(
              _controller.pins.length,
              (index) => _buildReorderableItem(_controller.pins[index], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableItem(PinDto pin, int index) {
    final isSelected = _controller.selectedPinId == pin.pinId;
    return Column(
      key: ValueKey('route_reorder_item_${pin.pinId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            key: ValueKey('route_pin_tile_${pin.pinId}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(pin.locationName ?? pin.pinId),
            subtitle: _buildPinSubtitle(pin),
            onTap: () => _controller.selectPin(pin.pinId),
            trailing: ReorderableDragStartListener(
              key: ValueKey('route_pin_reorder_handle_${pin.pinId}'),
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
        ),
        if (index < _controller.segments.length)
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 12, bottom: 16),
            child: _buildSegmentSection(index),
          ),
      ],
    );
  }

  Widget _buildPinSubtitle(PinDto pin) {
    final visitStart = pin.visitStartDate;
    final visitEnd = pin.visitEndDate;

    if (visitStart == null && visitEnd == null) {
      return const SizedBox.shrink();
    }

    final parts = <String>[];
    if (visitStart != null) {
      parts.add('開始: ${_formatDateTime(visitStart)}');
    }
    if (visitEnd != null) {
      parts.add('終了: ${_formatDateTime(visitEnd)}');
    }

    return Text(parts.join('\n'));
  }

  Widget _buildSegmentSection(int segmentIndex) {
    final segment = _controller.segments[segmentIndex];
    final isHighlighted = _controller.selectedSegmentIndex == segmentIndex;

    return InkWell(
      onTap: () => _controller.selectSegment(segmentIndex),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(
              Icons.arrow_downward,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.blueGrey,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<RouteTravelMode>(
                  key: ValueKey('route_segment_mode_$segmentIndex'),
                  value: segment.travelMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      _controller.updateTravelMode(segmentIndex, mode);
                    }
                  },
                  items: RouteTravelMode.values
                      .map(
                        (mode) => DropdownMenuItem<RouteTravelMode>(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                _buildSegmentInfo(segment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentInfo(RouteInfoSegmentState segment) {
    if (_controller.isLoading) {
      return const Text('経路情報を計算中です...');
    }

    final candidate = segment.candidate;
    if (candidate == null) {
      return const Text('経路情報がまだ取得されていません。');
    }

    final description = candidate.description?.isNotEmpty == true
        ? candidate.description!
        : '候補情報なし';
    final distance = candidate.localizedDistanceText ?? '-';
    final duration = candidate.localizedDurationText ?? '-';

    final leg = candidate.legs.isNotEmpty ? candidate.legs.first : null;
    final legDistance = leg?.localizedDistanceText ?? '-';
    final legDuration = leg?.localizedDurationText ?? '-';
    final instruction = leg?.primaryInstruction ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('合計所要時間: $duration'),
          Text('合計距離: $distance'),
          const SizedBox(height: 8),
          Text('区間所要時間: $legDuration'),
          Text('区間距離: $legDistance'),
          Text('経路概要: $instruction'),
          if (candidate.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: candidate.warnings
                  .map((warning) => Text('注意: $warning'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final segment = _controller.selectedSegment;

    Widget buildPlaceholder() {
      final description = segment != null
          ? '${segment.from.pinId} → ${segment.to.pinId}'
          : '経路未選択';
      return Container(
        key: const Key('route_info_map_placeholder'),
        height: 240,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('ハイライト対象: $description'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('経路マップ', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: Icon(_isMapVisible ? Icons.remove : Icons.add),
              onPressed: () {
                setState(() {
                  _isMapVisible = !_isMapVisible;
                });
                if (_isMapVisible && !widget.isTestEnvironment) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateCameraForSelectedSegment();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isMapVisible)
          if (widget.isTestEnvironment)
            buildPlaceholder()
          else
            SizedBox(
              height: 240,
              child: GoogleMap(
                key: const Key('route_info_map'),
                initialCameraPosition: _initialCameraPosition(),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateCameraForSelectedSegment();
                },
                markers: _buildMarkers(),
                polylines: _buildPolylines(context),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  CameraPosition _initialCameraPosition() {
    if (_controller.pins.isEmpty) {
      return const CameraPosition(
        target: LatLng(35.681236, 139.767125),
        zoom: 10,
      );
    }
    final first = _controller.pins.first;
    return CameraPosition(
      target: LatLng(first.latitude, first.longitude),
      zoom: 12,
    );
  }

  Set<Marker> _buildMarkers() {
    return _controller.pins
        .map(
          (pin) => Marker(
            markerId: MarkerId(pin.pinId),
            position: LatLng(pin.latitude, pin.longitude),
            infoWindow: InfoWindow(title: pin.locationName ?? pin.pinId),
            onTap: () => _controller.selectPin(pin.pinId),
          ),
        )
        .toSet();
  }

  Set<Polyline> _buildPolylines(BuildContext context) {
    final polylines = <Polyline>{};

    for (var index = 0; index < _controller.segments.length; index++) {
      final segment = _controller.segments[index];
      final candidate = segment.candidate;
      if (candidate == null) {
        continue;
      }
      final points = _collectPolylinePoints(candidate);
      if (points.isEmpty) {
        continue;
      }
      final isHighlighted = _controller.selectedSegmentIndex == index;
      polylines.add(
        Polyline(
          polylineId: PolylineId('segment_$index'),
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary
              : Colors.blueGrey,
          width: isHighlighted ? 6 : 4,
          points: points,
        ),
      );
    }
    return polylines;
  }

  List<LatLng> _collectPolylinePoints(RouteCandidate candidate) {
    final points = <LatLng>[];
    for (final leg in candidate.legs) {
      if (leg.polylinePoints.isEmpty) {
        continue;
      }
      points.addAll(
        leg.polylinePoints.map(
          (point) => LatLng(point.latitude, point.longitude),
        ),
      );
    }
    return points;
  }

  Future<void> _updateCameraForSelectedSegment() async {
    if (_mapController == null) {
      return;
    }
    final segment = _controller.selectedSegment;
    if (segment == null) {
      return;
    }

    final candidate = segment.candidate;
    final points = candidate != null
        ? _collectPolylinePoints(candidate)
        : <LatLng>[];

    if (points.isEmpty) {
      final from = LatLng(segment.from.latitude, segment.from.longitude);
      final to = LatLng(segment.to.latitude, segment.to.longitude);
      await _animateCameraToBounds([from, to]);
      return;
    }

    await _animateCameraToBounds(points);
  }

  Future<void> _animateCameraToBounds(List<LatLng> points) async {
    if (points.isEmpty || _mapController == null) {
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 48),
      );
    } catch (error, stackTrace) {
      logger.w(
        '_RouteInfoDialogState._animateCameraToBounds: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
