import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';

class SharedPreferencesCalendarGroupSettingsStorage
    implements CalendarGroupSettingsStorage {
  const SharedPreferencesCalendarGroupSettingsStorage();
  String _key(String ownerId) =>
      'calendar_groups_${Uri.encodeComponent(ownerId)}';

  @override
  Future<CalendarGroupSettings> load(String ownerId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(ownerId));
    if (raw == null) return CalendarGroupSettings(hasSavedSettings: false);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return CalendarGroupSettings(
      visibleGroupIds: (data['visibleGroupIds'] as List).cast<String>().toSet(),
      defaultGroupId: data['defaultGroupId'] as String?,
    );
  }

  @override
  Future<void> save(String ownerId, CalendarGroupSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(
      _key(ownerId),
      jsonEncode({
        'visibleGroupIds': settings.visibleGroupIds.toList(),
        'defaultGroupId': settings.defaultGroupId,
      }),
    )) {
      throw StateError('カレンダーのグループ設定を保存できませんでした');
    }
  }
}
