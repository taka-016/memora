import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../infrastructure/repositories/pin_repository_impl.dart';

class LoadPinsUseCase {
  final PinRepositoryImpl _pinRepository;

  LoadPinsUseCase(this._pinRepository);

  /// ピンの位置リストを取得し、Google Maps用のLatLngリストに変換して返す
  Future<List<LatLng>> execute() async {
    final pins = await _pinRepository.getPins();
    return pins.map((pin) => LatLng(pin.latitude, pin.longitude)).toList();
  }
}
