import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/composition_root/providers/theme_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_settings_notifier.g.dart';

class ThemeSettingsState {
  const ThemeSettingsState({required this.mode, this.isSaving = false});

  final AppThemeMode mode;
  final bool isSaving;
}

Duration? _noThemeSettingsRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noThemeSettingsRetry)
class ThemeSettingsNotifier extends _$ThemeSettingsNotifier {
  @override
  Future<ThemeSettingsState> build() async => ThemeSettingsState(
    mode: await ref.watch(appThemeModeStorageProvider).load(),
  );

  Future<bool> save(AppThemeMode mode) async {
    final previous = state.value;
    if (previous == null || previous.isSaving) return false;
    if (previous.mode == mode) return true;
    state = AsyncData(ThemeSettingsState(mode: previous.mode, isSaving: true));
    try {
      await ref.read(appThemeModeStorageProvider).save(mode);
      if (ref.mounted) state = AsyncData(ThemeSettingsState(mode: mode));
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(previous);
      return false;
    }
  }
}
