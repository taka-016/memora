import 'package:flutter/material.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/env/env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/infrastructure/services/geolocator_current_location_service.dart';
import 'package:memora/presentation/widgets/search_bar.dart';
import 'package:memora/infrastructure/services/google_places_api_location_search_service.dart';
import 'package:memora/presentation/widgets/pin_detail_bottom_sheet.dart';

class MapDisplay extends StatelessWidget {
  final List<Pin> pins;
  final CurrentLocationService? locationService;
  final Function(LatLng)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(String)? onMarkerDeleted;

  const MapDisplay({
    super.key,
    required this.pins,
    this.locationService,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return _MapDisplayWidget(
      pins: pins,
      locationService: locationService,
      onMapLongTapped: onMapLongTapped,
      onMarkerTapped: onMarkerTapped,
      onMarkerDeleted: onMarkerDeleted,
    );
  }
}

class _MapDisplayWidget extends StatefulWidget {
  final List<Pin> pins;
  final CurrentLocationService? locationService;
  final Function(LatLng)? onMapLongTapped;
  final Function(Pin)? onMarkerTapped;
  final Function(String)? onMarkerDeleted;

  const _MapDisplayWidget({
    required this.pins,
    this.locationService,
    this.onMapLongTapped,
    this.onMarkerTapped,
    this.onMarkerDeleted,
  });

  @override
  State<_MapDisplayWidget> createState() => _MapDisplayWidgetState();
}

class _MapDisplayWidgetState extends State<_MapDisplayWidget> {
  static const LatLng _defaultPosition = LatLng(35.681236, 139.767125);
  GoogleMapController? _mapController;
  bool _isBottomSheetVisible = false;
  Pin? _selectedPin;

  CurrentLocationService get _locationService =>
      widget.locationService ?? GeolocatorCurrentLocationService();

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

  Future<void> _moveToCurrentLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('現在地が取得できませんでした')));
        return;
      }
      final location = LatLng(loc.latitude, loc.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('現在地取得に失敗: $e')));
    }
  }

  Future<void> _moveToSearchedLocation(
    double latitude,
    double longitude,
  ) async {
    final location = LatLng(latitude, longitude);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapLongTap(LatLng position) {
    if (widget.onMapLongTapped != null) {
      widget.onMapLongTapped!(position);
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
      key: const Key('map_display'),
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _defaultPosition,
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
                await _moveToSearchedLocation(
                  candidate.latitude,
                  candidate.longitude,
                );
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
