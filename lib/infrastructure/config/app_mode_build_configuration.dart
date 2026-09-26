import 'package:memora/application/models/app_mode.dart';

class AppModeBuildConfiguration {
  const AppModeBuildConfiguration._({
    required this.requestedValue,
    required this.forcedMode,
  });

  static const environmentKey = 'MEMORA_APP_MODE';

  final String requestedValue;
  final AppMode? forcedMode;

  factory AppModeBuildConfiguration.fromEnvironment() {
    const value = String.fromEnvironment(
      environmentKey,
      defaultValue: 'online',
    );
    return AppModeBuildConfiguration.parse(value);
  }

  factory AppModeBuildConfiguration.parse(String value) {
    return switch (value) {
      'online' => const AppModeBuildConfiguration._(
        requestedValue: 'online',
        forcedMode: AppMode.online,
      ),
      'offline' => const AppModeBuildConfiguration._(
        requestedValue: 'offline',
        forcedMode: AppMode.offline,
      ),
      _ => throw ArgumentError.value(
        value,
        environmentKey,
        '$environmentKeyにはonline、offlineのいずれかを指定してください',
      ),
    };
  }
}
