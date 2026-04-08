import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TimelineDisplaySettings.definitions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('表示設定定義から保存キーと表示名を取得できる', () {
      final definitions = TimelineDisplaySettings.definitions;

      expect(definitions.map((definition) => definition.storageKey), [
        TimelineDisplaySettings.showAgeKey,
        TimelineDisplaySettings.showGradeKey,
        TimelineDisplaySettings.showYakudoshiKey,
      ]);
      expect(definitions.map((definition) => definition.label), [
        '年齢を表示',
        '学年を表示',
        '厄年を表示',
      ]);
    });

    test('表示設定定義から現在値参照と更新を行える', () {
      final settings = TimelineDisplaySettings.defaults;
      final ageDefinition = TimelineDisplaySettings.definitions.first;

      expect(ageDefinition.getValue(settings), isTrue);

      final updated = ageDefinition.update(settings, false);
      expect(updated.showAge, isFalse);
      expect(updated.showGrade, isTrue);
      expect(updated.showYakudoshi, isTrue);
    });

    test('表示設定定義は外部から変更できない', () {
      expect(
        () => TimelineDisplaySettings.definitions.add(
          TimelineDisplaySettingDefinition(
            storageKey: 'dummy',
            toggleKey: 'dummy',
            label: 'dummy',
            getValue: (_) => false,
            update: (settings, _) => settings,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('保存した設定を定義経由で読み戻せる', () async {
      final settings = const TimelineDisplaySettings(
        showAge: false,
        showGrade: true,
        showYakudoshi: false,
      );

      await settings.save();
      final loaded = await TimelineDisplaySettings.load();

      for (final definition in TimelineDisplaySettings.definitions) {
        expect(
          definition.getValue(loaded),
          definition.getValue(settings),
        );
      }
    });
  });
}
