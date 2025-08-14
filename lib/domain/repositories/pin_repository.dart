import 'package:memora/domain/entities/pin.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<List<Pin>> getPinsByTripId(String tripId);
  Future<void> savePin(String pinId, double latitude, double longitude);
  Future<void> savePinWithTrip(Pin pin);
  Future<void> deletePin(String pinId);
  Future<void> deletePinsByTripId(String tripId);
}
