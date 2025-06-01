import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> loadSavedPins(dynamic repository) async {
    markers.clear();
    final pins = await repository.loadPins();
    for (final pin in pins) {
      await addPin(pin, null);
    }
  }
}
