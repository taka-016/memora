import 'package:memora/application/models/app_mode.dart';

class AppModeResolver {
  const AppModeResolver();

  AppMode resolve({AppMode? forcedMode}) {
    return forcedMode ?? AppMode.online;
  }
}
