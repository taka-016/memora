import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/app_services.dart';
import 'package:memora/infrastructure/services/offline_app_services.dart';
import 'package:memora/infrastructure/services/online_app_services.dart';

class AppServicesFactory {
  static AppServices create(AppMode mode) => switch (mode) {
    AppMode.online => OnlineAppServices(),
    AppMode.offline => OfflineAppServices(),
  };
}
