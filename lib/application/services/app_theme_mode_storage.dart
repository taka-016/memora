import 'package:memora/application/models/app_theme_mode.dart';

abstract class AppThemeModeStorage {
  Future<AppThemeMode> load();
  Future<void> save(AppThemeMode mode);
}
