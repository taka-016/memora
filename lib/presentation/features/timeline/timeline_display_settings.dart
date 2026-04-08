import 'package:shared_preferences/shared_preferences.dart';

class TimelineDisplaySettingDefinition {
  const TimelineDisplaySettingDefinition({
    required this.storageKey,
    required this.toggleKey,
    required this.label,
    required this.getValue,
    required this.update,
  });

  final String storageKey;
  final String toggleKey;
  final String label;
  final bool Function(TimelineDisplaySettings settings) getValue;
  final TimelineDisplaySettings Function(
    TimelineDisplaySettings settings,
    bool value,
  )
  update;
}

class TimelineDisplaySettings {
  const TimelineDisplaySettings({
    required this.showAge,
    required this.showGrade,
    required this.showYakudoshi,
  });

  static const String showAgeKey = 'timeline_show_age';
  static const String showGradeKey = 'timeline_show_grade';
  static const String showYakudoshiKey = 'timeline_show_yakudoshi';

  static final List<TimelineDisplaySettingDefinition> definitions = [
    TimelineDisplaySettingDefinition(
      storageKey: showAgeKey,
      toggleKey: 'toggle_show_age',
      label: '年齢を表示',
      getValue: (settings) => settings.showAge,
      update: (settings, value) => settings.copyWith(showAge: value),
    ),
    TimelineDisplaySettingDefinition(
      storageKey: showGradeKey,
      toggleKey: 'toggle_show_grade',
      label: '学年を表示',
      getValue: (settings) => settings.showGrade,
      update: (settings, value) => settings.copyWith(showGrade: value),
    ),
    TimelineDisplaySettingDefinition(
      storageKey: showYakudoshiKey,
      toggleKey: 'toggle_show_yakudoshi',
      label: '厄年を表示',
      getValue: (settings) => settings.showYakudoshi,
      update: (settings, value) => settings.copyWith(showYakudoshi: value),
    ),
  ];

  static const TimelineDisplaySettings defaults = TimelineDisplaySettings(
    showAge: true,
    showGrade: true,
    showYakudoshi: true,
  );

  final bool showAge;
  final bool showGrade;
  final bool showYakudoshi;

  TimelineDisplaySettings copyWith({
    bool? showAge,
    bool? showGrade,
    bool? showYakudoshi,
  }) {
    return TimelineDisplaySettings(
      showAge: showAge ?? this.showAge,
      showGrade: showGrade ?? this.showGrade,
      showYakudoshi: showYakudoshi ?? this.showYakudoshi,
    );
  }

  static Future<TimelineDisplaySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TimelineDisplaySettings(
      showAge: prefs.getBool(showAgeKey) ?? defaults.showAge,
      showGrade: prefs.getBool(showGradeKey) ?? defaults.showGrade,
      showYakudoshi: prefs.getBool(showYakudoshiKey) ?? defaults.showYakudoshi,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final definition in definitions) {
      await prefs.setBool(definition.storageKey, definition.getValue(this));
    }
  }
}
