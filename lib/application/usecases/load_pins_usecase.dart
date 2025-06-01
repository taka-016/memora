import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class LoadPinsUseCase {
  final PinRepository _pinRepository;

  LoadPinsUseCase(this._pinRepository);

  /// ピンの位置リストを取得し、Google Maps用のLatLngリストに変換して返す
  Future<List<LatLng>> execute() async {
    final pins = await _pinRepository.getPins();
    return pins.map((pin) => LatLng(pin.latitude, pin.longitude)).toList();
  }
}
