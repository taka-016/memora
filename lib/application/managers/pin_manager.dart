import 'package:flutter_verification/domain/entities/pin.dart';
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

  Future<Marker> addMarker(
    LatLng position,
    MarkerId? markerId,
    VoidCallback? onTap,
  ) async {
    final uuid = Uuid();
    final marker = Marker(
      markerId: markerId ?? MarkerId(uuid.v4()),
      position: position,
      onTap: () {
        if (onTap != null) onTap();
        if (onPinTap != null) onPinTap!(position);
      },
    );
    markers.add(marker);
    return marker;
  }

  Future<void> removeMarker(MarkerId markerId) async {
    try {
      markers.removeWhere((m) => m.markerId == markerId);
      final deletePinUseCase = DeletePinUseCase(pinRepository);
      await deletePinUseCase.execute(markerId.value);
    } catch (e) {
      // markerが見つからない場合は何もしない
    }
  }

  Future<void> loadInitialMarkers(List<Pin> pins, VoidCallback? onTap) async {
    markers.clear();
    for (final pin in pins) {
      await addMarker(
        LatLng(pin.latitude, pin.longitude),
        MarkerId(pin.pinId),
        onTap,
      );
    }
  }

  Future<void> loadSavedMarkers() async {
    final loadPinsUseCase = LoadPinsUseCase(pinRepository);
    final pins = await loadPinsUseCase.execute();
    await loadInitialMarkers(pins, null);
  }

  Future<void> saveMarker(Marker marker) async {
    final savePinUseCase = SavePinUseCase(pinRepository);
    await savePinUseCase.execute(
      marker.markerId.value,
      marker.position.latitude,
      marker.position.longitude,
    );
  }
}
