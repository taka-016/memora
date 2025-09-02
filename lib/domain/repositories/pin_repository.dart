import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<List<Pin>> getPinsByTripId(String tripId, {List<OrderBy>? orderBy});
  Future<void> savePin(Pin pin);
  Future<void> savePinWithTrip(Pin pin);
  Future<void> deletePin(String pinId);
  Future<void> deletePinsByTripId(String tripId);
}
