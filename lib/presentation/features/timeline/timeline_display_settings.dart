import 'package:shared_preferences/shared_preferences.dart';

class TimelineDisplaySettings {
  const TimelineDisplaySettings({
    required this.showAge,
    required this.showGrade,
    required this.showYakudoshi,
  });

  static const String showAgeKey = 'timeline_show_age';
  static const String showGradeKey = 'timeline_show_grade';
  static const String showYakudoshiKey = 'timeline_show_yakudoshi';

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
    await prefs.setBool(showAgeKey, showAge);
    await prefs.setBool(showGradeKey, showGrade);
    await prefs.setBool(showYakudoshiKey, showYakudoshi);
  }
}
