import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/services/route_info_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';
import 'package:memora/domain/value_objects/travel_mode.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_info_service.dart';

class RouteInfoDialog extends StatefulWidget {
  const RouteInfoDialog({
    super.key,
    required this.pins,
    this.routeInfoService,
    this.isTestEnvironment = false,
  });

  final List<PinDto> pins;
  final RouteInfoService? routeInfoService;
  final bool isTestEnvironment;

  static Future<void> show({
    required BuildContext context,
    required List<PinDto> pins,
    RouteInfoService? routeInfoService,
    bool isTestEnvironment = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => RouteInfoDialog(
        pins: pins,
        routeInfoService: routeInfoService,
        isTestEnvironment: isTestEnvironment,
      ),
    );
  }

  @override
  RouteInfoDialogState createState() => RouteInfoDialogState();
}

class RouteInfoDialogState extends State<RouteInfoDialog> {
  late List<PinDto> _pins;
  late Map<String, TravelMode> _segmentModes;
  Map<String, RouteSegmentDetail> _segmentDetails = {};
  Map<String, bool> _segmentExpansion = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMapVisible = true;
  int? _selectedPinIndex;
  GoogleMapController? _mapController;

  RouteInfoService get _service =>
      widget.routeInfoService ??
      GoogleRoutesApiRouteInfoService(apiKey: Env.googlePlacesApiKey);

  @visibleForTesting
  Map<String, RouteSegmentDetail> get segmentDetails =>
      Map.unmodifiable(_segmentDetails);

  @visibleForTesting
  int? get selectedPinIndex => _selectedPinIndex;

  @override
  void initState() {
    super.initState();
    _pins = List<PinDto>.from(widget.pins);
    _segmentModes = _buildSegmentModes({});
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Map<String, TravelMode> _buildSegmentModes(Map<String, TravelMode> previous) {
    final map = <String, TravelMode>{};
    for (var i = 0; i < _pins.length - 1; i++) {
      final key = _segmentKey(_pins[i], _pins[i + 1]);
      map[key] = previous[key] ?? TravelMode.drive;
    }
    return map;
  }

  String _segmentKey(PinDto origin, PinDto destination) {
    return '${origin.pinId}->${destination.pinId}';
  }

  Future<void> _searchRoutes() async {
    if (_pins.length < 2) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final nextResults = <String, RouteSegmentDetail>{};

    try {
      for (var i = 0; i < _pins.length - 1; i++) {
        final origin = _pins[i];
        final destination = _pins[i + 1];
        final key = _segmentKey(origin, destination);
        final mode = _segmentModes[key] ?? TravelMode.drive;

        final detail = await _service.fetchRoute(
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
        nextResults[key] = detail;
      }

      if (!mounted) return;
      setState(() {
        _segmentDetails = nextResults;
        _segmentExpansion = {
          for (final entry in nextResults.entries) entry.key: false,
        };
      });
      if (!widget.isTestEnvironment) {
        await _fitMapToRoutes();
      }
    } catch (e, stackTrace) {
      logger.e(
        'RouteInfoDialogState._searchRoutes: ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = '経路の取得に失敗しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fitMapToRoutes() async {
    if (_segmentDetails.isEmpty || _mapController == null) {
      return;
    }

    final points = _segmentDetails.values
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

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _pins.removeAt(oldIndex);
      _pins.insert(newIndex, item);
      _segmentModes = _buildSegmentModes(_segmentModes);
      _segmentDetails = {};
      _segmentExpansion = {};
      _selectedPinIndex = null;
    });
  }

  void _onModeChanged(String key, TravelMode mode) {
    setState(() {
      _segmentModes = {..._segmentModes, key: mode};
    });
  }

  void _toggleSegmentExpansion(String key) {
    setState(() {
      final current = _segmentExpansion[key] ?? false;
      _segmentExpansion = {..._segmentExpansion, key: !current};
    });
  }

  Set<String> _activeSegmentKeys() {
    if (_selectedPinIndex == null) {
      return _segmentDetails.keys.toSet();
    }
    final set = <String>{};
    final index = _selectedPinIndex!;
    if (index - 1 >= 0) {
      set.add(_segmentKey(_pins[index - 1], _pins[index]));
    }
    if (index + 1 < _pins.length) {
      set.add(_segmentKey(_pins[index], _pins[index + 1]));
    }
    return set;
  }

  void _onPinTap(int index) {
    setState(() {
      if (_selectedPinIndex == index) {
        _selectedPinIndex = null;
      } else {
        _selectedPinIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildActionRow(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildBodyContent(context)),
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

  Widget _buildActionRow() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _searchRoutes,
          child: _isLoading
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

  Widget _buildBodyContent(BuildContext context) {
    const collapsedHeight = 56.0;
    final expandedHeight = widget.isTestEnvironment
        ? 200.0
        : (MediaQuery.of(context).size.height * 0.32).clamp(180.0, 320.0);

    return Column(
      children: [
        Expanded(
          child: Stack(
            key: const Key('route_info_list_area'),
            children: [Positioned.fill(child: _buildReorderableList())],
          ),
        ),
        const SizedBox(height: 2),
        Divider(height: 1),
        AnimatedContainer(
          key: const Key('route_info_map_area'),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: _isMapVisible ? expandedHeight : collapsedHeight,
          child: _buildMapAccordionContent(),
        ),
      ],
    );
  }

  Widget _buildMapAccordionContent() {
    return Column(
      children: [
        _buildMapToggleButton(),
        if (_isMapVisible) ...[Expanded(child: _buildMapSection())],
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
      ),
    );
  }

  Widget _buildReorderableList() {
    return Material(
      color: Colors.transparent,
      child: ReorderableListView.builder(
        key: const Key('route_info_reorderable_list'),
        padding: const EdgeInsets.only(right: 12),
        shrinkWrap: true,
        primary: false,
        cacheExtent: double.infinity,
        onReorder: _onReorder,
        itemCount: _pins.length,
        itemBuilder: (context, index) {
          final pin = _pins[index];
          return Column(
            key: ValueKey(pin.pinId),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  key: Key('route_info_pin_tile_${pin.pinId}'),
                  title: Text(pin.locationName ?? ''),
                  selected: _selectedPinIndex == index,
                  onTap: () => _onPinTap(index),
                  trailing: const Icon(Icons.drag_handle),
                ),
              ),
              if (index < _pins.length - 1)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_downward),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<TravelMode>(
                            key: Key('route_segment_mode_$index'),
                            value:
                                _segmentModes[_segmentKey(
                                  _pins[index],
                                  _pins[index + 1],
                                )] ??
                                TravelMode.drive,
                            underline: const SizedBox.shrink(),
                            items: TravelMode.values
                                .map(
                                  (mode) => DropdownMenuItem<TravelMode>(
                                    value: mode,
                                    child: Text(mode.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (mode) {
                              if (mode == null) return;
                              _onModeChanged(
                                _segmentKey(_pins[index], _pins[index + 1]),
                                mode,
                              );
                            },
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Container(
                              key: Key('route_segment_container_$index'),
                              child: _buildSegmentDetail(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegmentDetail(int index) {
    final key = _segmentKey(_pins[index], _pins[index + 1]);
    final detail = _segmentDetails[key];

    if (detail == null) {
      return const SizedBox.shrink();
    }

    final hasData =
        detail.distanceMeters > 0 ||
        detail.durationSeconds > 0 ||
        detail.instructions.isNotEmpty;

    if (!hasData) {
      return const SizedBox.shrink();
    }

    final isExpanded = _segmentExpansion[key] ?? false;
    final instructions = detail.instructions;
    final distanceLabel = _formatDistanceLabel(detail.distanceMeters);
    final durationMinutes = _durationMinutes(detail.durationSeconds);
    final summaryText =
        '距離: $distanceLabel'
        'km 所要時間: $durationMinutes'
        '分';
    const double maxDetailHeight = 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: Key('route_segment_toggle_$index'),
          onTap: () => _toggleSegmentExpansion(key),
          child: Row(
            key: Key('route_segment_summary_$index'),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                instructions.isEmpty
                    ? Icons.info_outline
                    : (isExpanded ? Icons.expand_less : Icons.expand_more),
                size: 20,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  summaryText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: isExpanded && instructions.isNotEmpty
              ? Padding(
                  key: ValueKey('route_segment_instructions_$index'),
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: SizedBox(
                    height: maxDetailHeight,
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: instructions
                              .map(
                                (instruction) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    instruction,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('route_segment_instructions_collapsed'),
                ),
        ),
      ],
    );
  }

  String _formatDistanceLabel(int meters) {
    if (meters <= 0) {
      return '0.0';
    }
    final distance = meters / 1000;
    final formatted = distance >= 100
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  int _durationMinutes(int seconds) {
    if (seconds <= 0) {
      return 0;
    }
    return (seconds / 60).ceil();
  }

  Widget _buildMapSection() {
    if (widget.isTestEnvironment) {
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
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _initialCameraPosition(),
          zoom: 12,
        ),
        polylines: _buildPolylines(),
        markers: _buildMarkers(),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }

  Widget _buildMapToggleButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('route_info_map_toggle'),
        onPressed: () {
          setState(() {
            _isMapVisible = !_isMapVisible;
          });
        },
        icon: Icon(_isMapVisible ? Icons.remove : Icons.add),
        label: Text(_isMapVisible ? 'マップ非表示' : 'マップ表示'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }

  LatLng _initialCameraPosition() {
    if (_pins.isNotEmpty) {
      final pin = _pins.first;
      return LatLng(pin.latitude, pin.longitude);
    }
    return const LatLng(35.681236, 139.767125);
  }

  Set<Marker> _buildMarkers() {
    return _pins
        .map(
          (pin) => Marker(
            markerId: MarkerId(pin.pinId),
            position: LatLng(pin.latitude, pin.longitude),
            infoWindow: InfoWindow(title: pin.locationName ?? ''),
          ),
        )
        .toSet();
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    final activeKeys = _activeSegmentKeys();

    _segmentDetails.forEach((key, detail) {
      if (detail.polyline.isEmpty) {
        return;
      }
      polylines.add(
        Polyline(
          polylineId: PolylineId(key),
          points: detail.polyline
              .map((location) => LatLng(location.latitude, location.longitude))
              .toList(),
          color: activeKeys.contains(key) ? Colors.blueAccent : Colors.blueGrey,
          width: activeKeys.contains(key) ? 6 : 4,
        ),
      );
    });

    return polylines;
  }
}
