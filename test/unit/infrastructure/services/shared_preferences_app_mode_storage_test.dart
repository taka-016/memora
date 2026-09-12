import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storage = SharedPreferencesAppModeStorage();
  for (final mode in AppMode.values) {
    test('${mode.name}の解決済みモードをネイティブと共通のキーへ保存する', () async {
      SharedPreferences.setMockInitialValues({});
      await storage.save(mode);
      expect(await storage.load(), mode);
      final forcedMode = AppModeBuildConfiguration.fromEnvironment().forcedMode;
      expect(await storage.loadForCurrentBuild(),
          forcedMode == null || forcedMode == mode ? mode : isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('resolved_app_mode'), mode.name);
    });
  }

  for (final value in [null, 'auto', 'unknown']) {
    test('保存値$valueからモードを推測せず未解決として扱う', () async {
      SharedPreferences.setMockInitialValues({'resolved_app_mode': ?value});
      expect(await storage.load(), isNull);
      expect(await storage.loadForCurrentBuild(), isNull);
    });
  }
}
