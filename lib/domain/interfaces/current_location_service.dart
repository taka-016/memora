import 'package:memora/domain/value_objects/location.dart';

abstract class CurrentLocationService {
  Future<Location?> getCurrentLocation();
}
