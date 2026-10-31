import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/application/services/app_theme_mode_storage.dart';
import 'package:memora/composition_root/providers/theme_providers.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'theme_settings_notifier_test.mocks.dart';

@GenerateMocks([AppThemeModeStorage])
void main() {
  late MockAppThemeModeStorage storage;
  late ProviderContainer container;
  setUp(() {
    storage = MockAppThemeModeStorage();
    when(storage.load()).thenAnswer((_) async => AppThemeMode.dark);
    container = ProviderContainer.test(
      overrides: [appThemeModeStorageProvider.overrideWithValue(storage)],
    );
  });

  test('保存完了まで元のテーマを保ち重複保存を防ぐ', () async {
    expect(
      (await container.read(themeSettingsNotifierProvider.future)).mode,
      AppThemeMode.dark,
    );
    final completion = Completer<void>();
    when(storage.save(AppThemeMode.light)).thenAnswer((_) => completion.future);
    final notifier = container.read(themeSettingsNotifierProvider.notifier);
    final saving = notifier.save(AppThemeMode.light);
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.mode,
      AppThemeMode.dark,
    );
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.isSaving,
      isTrue,
    );
    expect(await notifier.save(AppThemeMode.system), isFalse);
    verifyNever(storage.save(AppThemeMode.system));
    completion.complete();
    expect(await saving, isTrue);
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.mode,
      AppThemeMode.light,
    );
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.isSaving,
      isFalse,
    );
  });

  test('保存失敗時は元のテーマを保持し再試行できる', () async {
    await container.read(themeSettingsNotifierProvider.future);
    final notifier = container.read(themeSettingsNotifierProvider.notifier);
    when(storage.save(AppThemeMode.light)).thenThrow(TestException('保存失敗'));
    expect(await notifier.save(AppThemeMode.light), isFalse);
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.mode,
      AppThemeMode.dark,
    );
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.isSaving,
      isFalse,
    );
    when(storage.save(AppThemeMode.light)).thenAnswer((_) async {});
    expect(await notifier.save(AppThemeMode.light), isTrue);
    expect(
      container.read(themeSettingsNotifierProvider).requireValue.mode,
      AppThemeMode.light,
    );
  });

  test('読み込み失敗後は再取得で保存済みテーマを復元できる', () async {
    when(storage.load()).thenThrow(TestException('読込失敗'));
    await expectLater(
      container.read(themeSettingsNotifierProvider.future),
      throwsA(isA<TestException>()),
    );
    expect(container.read(themeSettingsNotifierProvider).hasError, isTrue);
    when(storage.load()).thenAnswer((_) async => AppThemeMode.light);
    container.invalidate(themeSettingsNotifierProvider);
    expect(
      (await container.read(themeSettingsNotifierProvider.future)).mode,
      AppThemeMode.light,
    );
  });
}
