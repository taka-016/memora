import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/app_theme_mode_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_theme_mode_storage.dart';

final appThemeModeStorageProvider = Provider<AppThemeModeStorage>(
  (ref) => const SharedPreferencesAppThemeModeStorage(),
);
