import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/env/env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/managers/location_manager.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

class GoogleMapView extends ConsumerWidget {
  final List<Pin> pins;
  final Function(Location)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(Pin)? onMarkerUpdated;
  final Function(String)? onMarkerDeleted;
  final Pin? selectedPin;

  const GoogleMapView({
    super.key,
    required this.pins,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerUpdated,
    this.onMarkerDeleted,
    this.selectedPin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GoogleMapViewWidget(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerUpdated: onMarkerUpdated,
      onMarkerDeleted: onMarkerDeleted,
      selectedPin: selectedPin,
    );
  }
}

class _GoogleMapViewWidget extends ConsumerStatefulWidget {
  final List<Pin> pins;
  final Function(Location)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(Pin)? onMarkerUpdated;
  final Function(String)? onMarkerDeleted;
  final Pin? selectedPin;

  const _GoogleMapViewWidget({
    required this.pins,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerUpdated,
    this.onMarkerDeleted,
    this.selectedPin,
  });

  @override
  ConsumerState<_GoogleMapViewWidget> createState() =>
      _GoogleMapViewWidgetState();
}

class _GoogleMapViewWidgetState extends ConsumerState<_GoogleMapViewWidget> {
  static const LatLng _fallbackPosition = LatLng(35.681236, 139.767125); // 東京駅

  GoogleMapController? _mapController;
  bool _isBottomSheetVisible = false;
  Pin? _selectedPin;

  Set<Marker> get _markers {
    return widget.pins.map((pin) {
      return Marker(
        markerId: MarkerId(pin.pinId),
        position: LatLng(pin.latitude, pin.longitude),
        onTap: () => _onMarkerTap(pin),
      );
    }).toSet();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_GoogleMapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPin != null &&
        widget.selectedPin != oldWidget.selectedPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMarkerTap(widget.selectedPin!);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _animateToPosition(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15),
      ),
    );
  }

  LatLng _getCurrentOrFallbackPosition() {
    if (widget.pins.isNotEmpty) {
      final firstPin = widget.pins.first;
      return LatLng(firstPin.latitude, firstPin.longitude);
    }
    final location = ref.read(locationProvider).location;
    return location != null
        ? LatLng(location.latitude, location.longitude)
        : _fallbackPosition;
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      final location = ref.read(locationProvider).location;

      if (location == null) {
        if (!mounted) return;
        _showErrorSnackBar('現在地が取得できませんでした');
        return;
      }

      _animateToPosition(LatLng(location.latitude, location.longitude));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('現在地取得に失敗: $e');
    }
  }

  Future<void> _moveToSearchedLocation(Location location) async {
    _animateToPosition(LatLng(location.latitude, location.longitude));
    if (widget.onMapLongTapped != null) {
      widget.onMapLongTapped!(
        Location(latitude: location.latitude, longitude: location.longitude),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapLongTap(LatLng position) {
    if (widget.onMapLongTapped != null) {
      widget.onMapLongTapped!(
        Location(latitude: position.latitude, longitude: position.longitude),
      );
    }
  }

  void _onMarkerTap(Pin pin) {
    if (widget.onMarkerTapped != null) {
      widget.onMarkerTapped!(pin);
    }
    setState(() {
      _selectedPin = pin;
      _isBottomSheetVisible = true;
    });
  }

  void _hidePinDetailBottomSheet() {
    setState(() {
      _isBottomSheetVisible = false;
      _selectedPin = null;
    });
  }

  void _onMarkerDelete(pinId) async {
    if (widget.onMarkerDeleted != null) {
      widget.onMarkerDeleted!(pinId);
    }
    _hidePinDetailBottomSheet();
  }

  void _onMarkerUpdate(Pin pin) {
    if (widget.onMarkerUpdated != null) {
      widget.onMarkerUpdated!(pin);
    }
    _hidePinDetailBottomSheet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('map_view'),
      child: Stack(
        children: [
          _buildGoogleMap(),
          _buildSearchBar(),
          _buildLocationButton(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _getCurrentOrFallbackPosition(),
        zoom: 15,
      ),
      markers: _markers,
      onLongPress: _onMapLongTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildSearchBar() {
    final locationSearchService = GooglePlacesApiLocationSearchService(
      apiKey: Env.googlePlacesApiKey,
    );

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: CustomSearchBar(
        hintText: '場所を検索',
        locationSearchService: locationSearchService,
        onCandidateSelected: (candidate) async {
          await _moveToSearchedLocation(candidate.location);
        },
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 180,
      right: 4,
      child: FloatingActionButton(
        heroTag: 'my_location_fab',
        onPressed: _moveToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (!_isBottomSheetVisible || _selectedPin == null) {
      return const SizedBox.shrink();
    }

    return PinDetailBottomSheet(
      pin: _selectedPin!,
      onUpdate: _onMarkerUpdate,
      onDelete: _onMarkerDelete,
      onClose: _hidePinDetailBottomSheet,
    );
  }
}
