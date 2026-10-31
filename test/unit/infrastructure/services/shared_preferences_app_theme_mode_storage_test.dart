import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_theme_mode_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('未設定時は端末に従い選択したテーマを新しい保存先インスタンスでも復元できる', () async {
    const storage = SharedPreferencesAppThemeModeStorage();
    expect(await storage.load(), AppThemeMode.system);
    for (final mode in AppThemeMode.values) {
      await storage.save(mode);
      expect(await const SharedPreferencesAppThemeModeStorage().load(), mode);
    }
  });
}
