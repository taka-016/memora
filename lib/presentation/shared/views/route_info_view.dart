import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class RouteInfoView extends StatefulWidget {
  const RouteInfoView({
    super.key,
    required this.pins,
    this.routeInfoService,
    this.onClose,
    this.isTestEnvironment = false,
  });

  final List<PinDto> pins;
  final RouteInfoService? routeInfoService;
  final VoidCallback? onClose;
  final bool isTestEnvironment;

  @override
  RouteInfoViewState createState() => RouteInfoViewState();
}

class RouteInfoViewState extends State<RouteInfoView> {
  static const double _inactivePolylineOpacity = 0.4;

  late List<PinDto> _pins;
  late Map<String, TravelMode> _segmentModes;
  Map<String, RouteSegmentDetail> _segmentDetails = {};
  Map<String, bool> _routeMemoExpansion = {};
  final Map<String, RouteMemoEditFormValue> _otherRouteInfoInputs = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMapVisible = true;
  int? _selectedPinIndex;
  GoogleMapController? _mapController;

  RouteInfoService get _service =>
      widget.routeInfoService ??
      GoogleRoutesApiRouteInfoService(apiKey: Env.googlePlacesApiKey);

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @visibleForTesting
  Map<String, RouteSegmentDetail> get segmentDetails =>
      Map.unmodifiable(_segmentDetails);

  @visibleForTesting
  int? get selectedPinIndex => _selectedPinIndex;

  @visibleForTesting
  Map<String, Color> get segmentHighlightColors {
    final polylines = _buildPolylines();
    return {
      for (final polyline in polylines)
        polyline.polylineId.value: polyline.color,
    };
  }

  @visibleForTesting
  void selectPinForTest(int index) {
    if (index < 0 || index >= _pins.length) {
      return;
    }
    setState(() {
      _selectedPinIndex = index;
    });
  }

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
    _cleanupOtherRouteInfoInputs(map.keys);
    return map;
  }

  String _segmentKey(PinDto origin, PinDto destination) {
    return '${origin.pinId}->${destination.pinId}';
  }

  RouteMemoEditFormValue _ensureOtherRouteInfoValue(String key) {
    return _otherRouteInfoInputs.putIfAbsent(
      key,
      () => const RouteMemoEditFormValue.empty(),
    );
  }

  void _cleanupOtherRouteInfoInputs(Iterable<String> validKeys) {
    final validKeySet = validKeys.toSet();
    _otherRouteInfoInputs.removeWhere((key, _) => !validKeySet.contains(key));
  }

  void _updateOtherRouteInfo(String key, RouteMemoEditFormValue value) {
    if (!mounted) {
      return;
    }
    final sanitizedDuration =
        value.durationMinutes != null && value.durationMinutes! > 0
        ? value.durationMinutes
        : null;
    final sanitizedInstructions = value.instructions.trim();
    final normalized = RouteMemoEditFormValue(
      durationMinutes: sanitizedDuration,
      instructions: sanitizedInstructions,
    );
    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(() {
        if (normalized.isEmpty) {
          _otherRouteInfoInputs.remove(key);
        } else {
          _otherRouteInfoInputs[key] = normalized;
        }
      });
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      applyUpdate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
    }
  }

  Future<void> _openOtherRouteInfoSheet(String key) async {
    final initialValue =
        _otherRouteInfoInputs[key] ?? const RouteMemoEditFormValue.empty();

    final result = await showModalBottomSheet<RouteMemoEditFormValue>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RouteMemoEditBottomSheet(
          initialValue: initialValue,
          onChanged: (value) => _updateOtherRouteInfo(key, value),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      _updateOtherRouteInfo(key, result);
    }
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

        RouteSegmentDetail detail = await _service.fetchRoute(
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

        if (mode == TravelMode.other) {
          final otherInfo = _otherRouteInfoInputs[key];
          final customInstructions = _buildCustomInstructions(otherInfo);
          final customDurationSeconds = _customDurationSeconds(otherInfo);
          detail = detail.copyWith(
            instructions: customInstructions.isEmpty
                ? detail.instructions
                : customInstructions,
            durationSeconds: customDurationSeconds > 0
                ? customDurationSeconds
                : detail.durationSeconds,
          );
        }
        nextResults[key] = detail;
      }

      if (!mounted) return;
      setState(() {
        _segmentDetails = nextResults;
        _routeMemoExpansion = {
          for (final entry in nextResults.entries) entry.key: false,
        };
      });
      if (!widget.isTestEnvironment) {
        await _fitMapToRoutes();
      }
    } catch (e, stackTrace) {
      logger.e(
        'RouteInfoViewState._searchRoutes: ${e.toString()}',
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
      _routeMemoExpansion = {};
      _selectedPinIndex = null;
    });
  }

  void _onModeChanged(String key, TravelMode mode) {
    setState(() {
      _segmentModes = {..._segmentModes, key: mode};
      if (mode == TravelMode.other) {
        _ensureOtherRouteInfoValue(key);
      } else {
        _otherRouteInfoInputs.remove(key);
      }
    });
  }

  void _toggleRouteMemoExpansion(String key) {
    setState(() {
      final current = _routeMemoExpansion[key] ?? false;
      _routeMemoExpansion = {..._routeMemoExpansion, key: !current};
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
    return SizedBox(
      key: const Key('route_info_view_root'),
      width: double.infinity,
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
          onPressed: () => _handleClose(context),
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
              _buildPinListItem(pin, index),
              if (index < _pins.length - 1) _buildRouteSegment(index),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinListItem(PinDto pin, int index) {
    return Card(
      child: ListTile(
        key: Key('route_info_pin_tile_${pin.pinId}'),
        title: Text(pin.locationName ?? ''),
        selected: _selectedPinIndex == index,
        onTap: () => _onPinTap(index),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }

  Widget _buildRouteSegment(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 12),
        const Icon(Icons.arrow_downward),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTravelModeDropdown(index),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Container(
                  key: Key('route_segment_container_$index'),
                  child: _buildRouteMemoView(index),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelModeDropdown(int index) {
    final key = _segmentKey(_pins[index], _pins[index + 1]);
    final currentMode = _segmentModes[key] ?? TravelMode.drive;
    final dropdown = DropdownButton<TravelMode>(
      key: Key('route_segment_mode_$index'),
      value: currentMode,
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
        _onModeChanged(key, mode);
      },
    );

    if (currentMode != TravelMode.other) {
      return dropdown;
    }

    _ensureOtherRouteInfoValue(key);

    return Row(
      children: [
        Flexible(fit: FlexFit.loose, child: dropdown),
        IconButton(
          key: Key('route_segment_other_route_icon_$index'),
          onPressed: () => _openOtherRouteInfoSheet(key),
          icon: const Icon(Icons.edit),
          tooltip: '経路入力',
        ),
      ],
    );
  }

  Widget _buildRouteMemoView(int index) {
    final key = _segmentKey(_pins[index], _pins[index + 1]);
    final detail = _segmentDetails[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRouteMemoToggle(index, key),
        _buildRouteMemo(index, key, detail),
      ],
    );
  }

  Widget _buildRouteMemoToggle(int index, String key) {
    final isExpanded = _routeMemoExpansion[key] ?? false;

    return InkWell(
      key: Key('route_memo_toggle_button_$index'),
      onTap: () => _toggleRouteMemoExpansion(key),
      child: Row(
        key: Key('route_memo_toggle_label_$index'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'ルートメモ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMemo(int index, String key, RouteSegmentDetail? detail) {
    final isExpanded = _routeMemoExpansion[key] ?? false;
    const double maxDetailHeight = 120.0;
    final memoEntries = detail == null
        ? <Widget>[]
        : _buildRouteMemoEntries(detail);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isExpanded
          ? Padding(
              key: ValueKey('route_memo_$index'),
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: maxDetailHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: memoEntries,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('route_memo_collapsed')),
    );
  }

  List<Widget> _buildRouteMemoEntries(RouteSegmentDetail detail) {
    final entries = <Widget>[];
    final distanceLabel = _formatDistanceLabel(detail.distanceMeters);
    final durationMinutes = _durationMinutes(detail.durationSeconds);

    if (detail.distanceMeters > 0) {
      entries.add(_buildMemoLabel('距離: 約${distanceLabel}km'));
    }
    if (durationMinutes > 0) {
      entries.add(_buildMemoLabel('所要時間: 約$durationMinutes分'));
    }
    if (detail.instructions.isNotEmpty) {
      entries.add(_buildMemoLabel('経路案内'));
      entries.addAll(
        detail.instructions
            .map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(instruction, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
      );
    }

    return entries;
  }

  Widget _buildMemoLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  List<String> _buildCustomInstructions(RouteMemoEditFormValue? info) {
    if (info == null || info.instructions.isEmpty) {
      return const <String>[];
    }
    return info.instructions
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  int _customDurationSeconds(RouteMemoEditFormValue? info) {
    final minutes = info?.durationMinutes;
    if (minutes == null || minutes <= 0) {
      return 0;
    }
    return minutes * 60;
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
    final keys = _segmentDetails.keys.toList();

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final detail = _segmentDetails[key];
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

  Color _colorForPolylineIndex(int index, bool isActive) {
    if (isActive) {
      return ColorConstants.getSequentialColor(index);
    }
    return ColorConstants.getSequentialColorWithOpacity(
      index,
      _inactivePolylineOpacity,
    );
  }
}
