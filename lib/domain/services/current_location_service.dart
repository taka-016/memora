import 'package:memora/core/models/coordinate.dart';

abstract class CurrentLocationService {
  Future<Coordinate?> getCurrentLocation();
}
