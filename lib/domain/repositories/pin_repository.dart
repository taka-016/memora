import 'package:flutter_verification/domain/entities/pin.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<void> savePin(String markerId, double latitude, double longitude);
  Future<void> deletePin(String markerId);
}
