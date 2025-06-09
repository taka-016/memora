import 'package:memora/domain/entities/pin.dart';

abstract class PinRepository {
  Future<List<Pin>> getPins();
  Future<void> savePin(String pinId, double latitude, double longitude);
  Future<void> deletePin(String pinId);
}
