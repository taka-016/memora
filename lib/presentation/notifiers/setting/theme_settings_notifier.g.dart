// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeSettingsNotifier)
final themeSettingsNotifierProvider = ThemeSettingsNotifierProvider._();

final class ThemeSettingsNotifierProvider
    extends $AsyncNotifierProvider<ThemeSettingsNotifier, ThemeSettingsState> {
  ThemeSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noThemeSettingsRetry,
        name: r'themeSettingsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSettingsNotifierHash();

  @$internal
  @override
  ThemeSettingsNotifier create() => ThemeSettingsNotifier();
}

String _$themeSettingsNotifierHash() =>
    r'70bd64d100fe07b150ee78214cccb5329e645ef3';

abstract class _$ThemeSettingsNotifier
    extends $AsyncNotifier<ThemeSettingsState> {
  FutureOr<ThemeSettingsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ThemeSettingsState>, ThemeSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeSettingsState>, ThemeSettingsState>,
              AsyncValue<ThemeSettingsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
