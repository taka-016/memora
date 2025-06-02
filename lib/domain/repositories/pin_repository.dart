import 'package:flutter_verification/domain/entities/pin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<void> savePin(LatLng position);
  Future<void> deletePin(String pinId);
}
