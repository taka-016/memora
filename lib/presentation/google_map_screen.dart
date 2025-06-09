import 'package:flutter/material.dart';
import 'package:flutter_verification/domain/entities/pin.dart';
import 'package:flutter_verification/env/env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/infrastructure/services/geolocator_current_location_service.dart';
import 'package:flutter_verification/domain/services/current_location_service.dart';
import 'package:flutter_verification/application/managers/google_map_marker_manager.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:flutter_verification/presentation/widgets/search_bar.dart';
import 'package:flutter_verification/infrastructure/services/google_places_api_location_search_service.dart';

class GoogleMapScreen extends StatefulWidget {
  final List<Pin>? initialPins;
  final CurrentLocationService? locationService;
  final PinRepository? pinRepository;

  const GoogleMapScreen({
    super.key,
    this.initialPins,
    this.locationService,
    this.pinRepository,
  });

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  static const LatLng _defaultPosition = LatLng(35.681236, 139.767125);
  late final GoogleMapMarkerManager _pinManager;
  GoogleMapController? _mapController;

  CurrentLocationService get _locationService =>
      widget.locationService ?? GeolocatorCurrentLocationService();

  @override
  void initState() {
    super.initState();
    _pinManager = GoogleMapMarkerManager(
      pinRepository: widget.pinRepository ?? FirestorePinRepository(),
    );
    _pinManager.onPinTap = (LatLng position) {
      final marker = _pinManager.markers.firstWhere(
        (m) => m.position == position,
      );
      final index = _pinManager.markers.indexOf(marker);
      _onMarkerTap(marker.markerId, position, index);
    };
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadInitialMarkers();
    await _loadSavedMarkers();
    setState(() {});
  }

  Future<void> _loadInitialMarkers() async {
    if (widget.initialPins != null) {
      await _pinManager.loadInitialMarkers(widget.initialPins!, null);
    }
  }

  Future<void> _addMarker(LatLng position) async {
    Marker marker = await _pinManager.addMarker(position, null, null);
    setState(() {});
    try {
      await _pinManager.saveMarker(marker);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マーカーを保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('マーカー保存に失敗: $e')));
      }
    }
  }

  Future<void> _loadSavedMarkers() async {
    try {
      await _pinManager.loadSavedMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('マーカーの読み込みに失敗: $e')));
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveToCurrentLocation();
  }

  Future<void> _removeMarker(MarkerId markerId) async {
    try {
      await _pinManager.removeMarker(markerId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マーカーを削除しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('マーカー削除に失敗: $e')));
      }
    }
  }

  void _onMarkerTap(MarkerId markerId, LatLng position, int markerIndex) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset overlayOffset = overlay.localToGlobal(Offset.zero);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlayOffset.dx + 100,
        overlayOffset.dy + 200,
        overlayOffset.dx + 100,
        overlayOffset.dy + 200,
      ),
      items: [const PopupMenuItem<String>(value: 'delete', child: Text('削除'))],
    );
    if (selected == 'delete') {
      await _removeMarker(markerId);
    }
  }

  Future<void> _moveToCurrentLocation() async {
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

  @override
  Widget build(BuildContext context) {
    final locationSearchService = GooglePlacesApiLocationSearchService(
      apiKey: Env.googlePlacesApiKey,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Googleマップ')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _defaultPosition,
              zoom: 15,
            ),
            markers: _pinManager.markers.toSet(),
            onTap: _addMarker,
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
          ..._pinManager.markers.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final marker = entry.value;
            return Positioned(
              left: 100.0 + i * 10,
              top: 200.0 + i * 10,
              child: GestureDetector(
                key: Key('map_marker_$i'),
                onTap: () => _onMarkerTap(marker.markerId, marker.position, i),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(width: 40, height: 40),
              ),
            );
          }),
          Positioned(
            bottom: 180,
            right: 4,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
