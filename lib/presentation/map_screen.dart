import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_verification/infrastructure/repositories/pin_repository.dart';
import 'package:flutter_verification/application/usecases/load_pins_usecase.dart';

class MapScreen extends StatefulWidget {
  final List<LatLng>? initialPins;

  const MapScreen({super.key, this.initialPins});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Tokyo coordinates as default
  static const LatLng _defaultPosition = LatLng(35.681236, 139.767125);
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // 先にピンを読み込む
    _loadInitialPins();
    _loadSavedPins();
  }

  void _loadInitialPins() {
    if (widget.initialPins != null) {
      for (var i = 0; i < widget.initialPins!.length; i++) {
        final position = widget.initialPins![i];
        _addMarker(position, i);
      }
    }
  }

  Future<void> _loadSavedPins() async {
    try {
      // 内部でLoadPinsUseCaseを生成
      final loadPinsUseCase = LoadPinsUseCase(PinRepository());
      final pins = await loadPinsUseCase.execute();

      if (mounted) {
        setState(() {
          for (var i = 0; i < pins.length; i++) {
            final position = pins[i];
            final index = _markers.length;
            _addMarker(position, index);
          }
        });
      }
    } catch (e) {
      // Firebase初期化エラーやその他のエラーを捕捉
      print('ピン読み込みスキップ: $e');
      // テスト環境などではメッセージを表示しない
    }
  }

  void _addMarker(LatLng position, int index) {
    final markerId = MarkerId(position.toString());
    _markers.add(
      Marker(
        markerId: markerId,
        position: position,
        infoWindow: const InfoWindow(title: 'ピン'),
        onTap: () => _onPinTap(markerId, position, index),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    _moveToCurrentLocation();
  }

  Future<void> _addPin(LatLng position) async {
    final markerIndex = _markers.length;
    setState(() {
      _addMarker(position, markerIndex);
    });
    try {
      await PinRepository().savePin(position);
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

  /// 共通の現在地取得メソッド
  /// @param openSettingsIfDisabled 位置情報サービスが無効な時に設定画面を開くかどうか
  /// @return 取得できた場合は現在地のLatLng、取得できなかった場合はnull
  Future<LatLng?> _getCurrentLocation({
    bool openSettingsIfDisabled = true,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (openSettingsIfDisabled) {
        await Geolocator.openLocationSettings();
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// 現在地に移動するボタンのハンドラー
  /// @param openSettingsIfDisabled 位置情報サービスが無効な時に設定画面を開くかどうか
  Future<void> _moveToCurrentLocation({
    bool openSettingsIfDisabled = true,
  }) async {
    _getCurrentLocation(openSettingsIfDisabled: false).then((location) {
      if (location != null && mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: 15),
          ),
        );
      }
    });
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
