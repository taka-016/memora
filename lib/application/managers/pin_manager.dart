import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_verification/infrastructure/repositories/pin_repository_impl.dart';
import 'package:flutter_verification/application/usecases/load_pins_usecase.dart';
import 'package:flutter_verification/application/usecases/save_pin_usecase.dart';

class PinManager {
  final List<Marker> markers = [];
  void Function(LatLng position)? onPinTap;

  Future<void> addPin(LatLng position, VoidCallback? onTap) async {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      onTap: () {
        if (onTap != null) onTap();
        if (onPinTap != null) onPinTap!(position);
      },
    );
    markers.add(marker);
  }

  void removePin(MarkerId markerId) {
    markers.removeWhere((m) => m.markerId == markerId);
  }

  Future<void> loadInitialPins(List<LatLng> pins, VoidCallback? onTap) async {
    markers.clear();
    for (final pin in pins) {
      await addPin(pin, onTap);
    }
  }

  /// Firestore等から保存済みピンをロードする
  Future<void> loadSavedPins() async {
    final loadPinsUseCase = LoadPinsUseCase(PinRepositoryImpl());
    final pins = await loadPinsUseCase.execute();
    await loadInitialPins(pins, null);
  }

  /// Firestore等にピンを保存する
  Future<void> savePin(LatLng position) async {
    final savePinUseCase = SavePinUseCase(PinRepositoryImpl());
    await savePinUseCase.execute(position);
  }
}
