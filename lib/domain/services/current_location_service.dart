import 'package:memora/domain/value-objects/location.dart';

abstract class CurrentLocationService {
  Future<Location?> getCurrentLocation();
}
