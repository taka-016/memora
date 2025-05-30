/// Googleマップ画面
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final List<LatLng>? initialPins;
  const MapScreen({super.key, this.initialPins});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _initialPosition = LatLng(35.681236, 139.767125); // 東京駅
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialPins != null) {
      for (var i = 0; i < widget.initialPins!.length; i++) {
        final position = widget.initialPins![i];
        final markerId = MarkerId(position.toString());
        _markers.add(
          Marker(
            markerId: markerId,
            position: position,
            infoWindow: const InfoWindow(title: 'ピン'),
            onTap: () => _onPinTap(markerId, position, i),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addPin(LatLng position) {
    final markerId = MarkerId(position.toString());
    final markerIndex = _markers.length;
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: position,
          infoWindow: const InfoWindow(title: 'ピン'),
          onTap: () => _onPinTap(markerId, position, markerIndex),
        ),
      );
    });
  }

  void _removePin(MarkerId markerId) {
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
    });
  }

  void _onPinTap(MarkerId markerId, LatLng position, int markerIndex) async {
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
      _removePin(markerId);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Googleマップ')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            markers: _markers,
            onTap: _addPin,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // テスト用: ピンの位置に透明なGestureDetectorを重ねてKeyを付与
          ..._markers.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final marker = entry.value;
            return Positioned(
              left: 100.0 + i * 10, // 仮の座標（実際のマップ座標と同期しない）
              top: 200.0 + i * 10,
              child: GestureDetector(
                key: Key('map_pin_$i'),
                onTap: () => _onPinTap(marker.markerId, marker.position, i),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(width: 40, height: 40),
              ),
            );
          }),
          Positioned(
            bottom: 100,
            right: 4,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
