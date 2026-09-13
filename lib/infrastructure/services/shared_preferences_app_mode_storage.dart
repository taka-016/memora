import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/app_mode_resolver.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppModeStorage {
  const SharedPreferencesAppModeStorage();

  static const _key = 'resolved_app_mode';

  Future<void> save(AppMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, mode.name)) {
      throw StateError('解決済みモードを保存できませんでした');
    }
  }

  Future<AppMode?> loadForCurrentBuild() async {
    final mode = await load();
    final configuration = AppModeBuildConfiguration.fromEnvironment();
    final buildMode = const AppModeResolver().resolve(
      forcedMode: configuration.forcedMode,
    );
    if (mode != buildMode) return null;
    return mode;
  }

  Future<AppMode?> load() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return switch (preferences.getString(_key)) {
      'online' => AppMode.online,
      'offline' => AppMode.offline,
      _ => null,
    };
  }
}
