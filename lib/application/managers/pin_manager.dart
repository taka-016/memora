import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_verification/application/usecases/load_pins_usecase.dart';
import 'package:flutter_verification/application/usecases/save_pin_usecase.dart';
import 'package:flutter_verification/application/usecases/delete_pin_usecase.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:uuid/uuid.dart';

class PinManager {
  final List<Marker> markers = [];
  void Function(LatLng position)? onPinTap;
  final PinRepository pinRepository;

  PinManager({required this.pinRepository});

  Future<Marker> addPin(LatLng position, VoidCallback? onTap) async {
    final uuid = Uuid();
    final marker = Marker(
      markerId: MarkerId(uuid.v4()),
      position: position,
      onTap: () {
        if (onTap != null) onTap();
        if (onPinTap != null) onPinTap!(position);
      },
    );
    markers.add(marker);
    return marker;
  }

  Future<void> removePin(MarkerId markerId) async {
    try {
      final marker = markers.firstWhere((m) => m.markerId == markerId);
      markers.removeWhere((m) => m.markerId == markerId);
      final deletePinUseCase = DeletePinUseCase(pinRepository);
      await deletePinUseCase.execute(
        marker.position.latitude,
        marker.position.longitude,
      );
    } catch (e) {
      // markerが見つからない場合は何もしない
    }
  }

  Future<void> loadInitialPins(List<LatLng> pins, VoidCallback? onTap) async {
    markers.clear();
    for (final pin in pins) {
      await addPin(pin, onTap);
    }
  }

  Future<void> loadSavedPins() async {
    final loadPinsUseCase = LoadPinsUseCase(pinRepository);
    final pins = await loadPinsUseCase.execute();
    await loadInitialPins(pins, null);
  }

  Future<void> savePin(Marker marker) async {
    final savePinUseCase = SavePinUseCase(pinRepository);
    await savePinUseCase.execute(
      marker.markerId.value,
      marker.position.latitude,
      marker.position.longitude,
    );
  }
}
