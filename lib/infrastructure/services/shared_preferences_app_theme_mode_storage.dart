import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/application/services/app_theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppThemeModeStorage implements AppThemeModeStorage {
  const SharedPreferencesAppThemeModeStorage();

  static const _key = 'app_theme_mode';

  @override
  Future<AppThemeMode> load() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(_key)) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  @override
  Future<void> save(AppThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key, mode.name)) {
      throw StateError('テーマを保存できませんでした');
    }
  }
}
