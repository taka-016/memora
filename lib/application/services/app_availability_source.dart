import 'package:memora/application/models/app_availability.dart';

abstract class AppAvailabilitySource {
  Future<AppAvailabilitySettings> load();
}
