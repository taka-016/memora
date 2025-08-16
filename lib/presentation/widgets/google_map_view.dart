import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/value-objects/location.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/env/env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/managers/location_manager.dart';
import 'package:memora/presentation/widgets/search_bar.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';
import 'package:memora/presentation/widgets/pin_detail_bottom_sheet.dart';

class GoogleMapView extends ConsumerWidget {
  final List<Pin> pins;
  final Function(Location)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(String)? onMarkerDeleted;

  const GoogleMapView({
    super.key,
    required this.pins,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GoogleMapViewWidget(
      pins: pins,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerDeleted: onMarkerDeleted,
    );
  }
}

class _GoogleMapViewWidget extends ConsumerStatefulWidget {
  final List<Pin> pins;
  final Function(Location)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(String)? onMarkerDeleted;

  const _GoogleMapViewWidget({
    required this.pins,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerDeleted,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveToCurrentLocation();
    });
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

  void _onMarkerDelete() async {
    if (_selectedPin != null && widget.onMarkerDeleted != null) {
      widget.onMarkerDeleted!(_selectedPin!.pinId);
    }
    _hidePinDetailBottomSheet();
  }

  @override
  Widget build(BuildContext context) {
    final locationSearchService = GooglePlacesApiLocationSearchService(
      apiKey: Env.googlePlacesApiKey,
    );

    return Container(
      key: const Key('map_view'),
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _getCurrentOrFallbackPosition(),
              zoom: 15,
            ),
            markers: _markers,
            onLongPress: _onMapLongTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
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
          ),
          Positioned(
            bottom: 180,
            right: 4,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          if (_isBottomSheetVisible && _selectedPin != null)
            PinDetailBottomSheet(
              onSave: () {},
              onDelete: _onMarkerDelete,
              onClose: _hidePinDetailBottomSheet,
            ),
        ],
      ),
    );
  }
}
