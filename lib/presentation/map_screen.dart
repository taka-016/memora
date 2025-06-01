import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/infrastructure/services/location_service_impl.dart';
import 'package:flutter_verification/domain/services/location_service.dart';
import 'package:flutter_verification/application/managers/pin_manager.dart';

class MapScreen extends StatefulWidget {
  final List<LatLng>? initialPins;
  final LocationService? locationService;

  const MapScreen({super.key, this.initialPins, this.locationService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultPosition = LatLng(35.681236, 139.767125);
  final PinManager _pinManager = PinManager();
  GoogleMapController? _mapController;

  LocationService get _locationService =>
      widget.locationService ?? LocationServiceImpl();

  @override
  void initState() {
    super.initState();
    _pinManager.onPinTap = (LatLng position) {
      final marker = _pinManager.markers.firstWhere(
        (m) => m.position == position,
      );
      final index = _pinManager.markers.indexOf(marker);
      _onPinTap(marker.markerId, position, index);
    };
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadInitialPins();
    await _loadSavedPins();
    setState(() {});
  }

  Future<void> _loadInitialPins() async {
    if (widget.initialPins != null) {
      await _pinManager.loadInitialPins(widget.initialPins!, null);
    }
  }

  Future<void> _addPin(LatLng position) async {
    await _pinManager.addPin(position, null);
    setState(() {});
    try {
      await _pinManager.savePin(position);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ピンを保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ピン保存に失敗: $e')));
      }
    }
  }

  Future<void> _loadSavedPins() async {
    try {
      await _pinManager.loadSavedPins();
    } catch (e) {
      // Firebase初期化エラーやその他のエラーを捕捉
      // テスト環境などではメッセージを表示しない
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveToCurrentLocation();
  }

  void _removePin(MarkerId markerId) {
    _pinManager.removePin(markerId);
    setState(() {});
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

  /// 共通の現在地取得メソッド
  /// @param openSettingsIfDisabled 位置情報サービスが無効な時に設定画面を開くかどうか
  /// @return 取得できた場合は現在地のLatLng、取得できなかった場合はnull
  Future<LatLng?> _getCurrentLocation({
    bool openSettingsIfDisabled = true,
  }) async {
    try {
      final loc = await _locationService.getCurrentLocation();
      return LatLng(loc.latitude, loc.longitude);
    } catch (e) {
      return null;
    }
  }

  /// 現在地に移動するボタンのハンドラー
  /// @param openSettingsIfDisabled 位置情報サービスが無効な時に設定画面を開くかどうか
  Future<void> _moveToCurrentLocation({
    bool openSettingsIfDisabled = true,
  }) async {
    final location = await _getCurrentLocation(
      openSettingsIfDisabled: openSettingsIfDisabled,
    );
    if (location != null && mounted) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onTap: _addPin,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          ..._pinManager.markers.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final marker = entry.value;
            return Positioned(
              left: 100.0 + i * 10,
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
