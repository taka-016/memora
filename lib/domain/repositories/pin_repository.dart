import 'package:flutter_verification/domain/entities/pin.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<void> savePin(String pinId, double latitude, double longitude);
  Future<void> deletePin(String pinId);
}
