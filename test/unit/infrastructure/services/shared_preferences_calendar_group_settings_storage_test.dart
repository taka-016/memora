import 'dart:convert';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_group_settings_storage.dart';

void main() {
  const storage = SharedPreferencesCalendarGroupSettingsStorage();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('背景側で一度読んだ後も別isolateの表示解除を読み直す', () async {
    await storage.save('online:a', CalendarGroupSettings(visibleGroupIds: {'g'}));
    expect((await storage.load('online:a')).visibleGroupIds, {'g'});
    await SharedPreferencesStorePlatform.instance.setValue('String', 'flutter.calendar_groups_online%3Aa', jsonEncode({'visibleGroupIds': [], 'defaultGroupId': null}));
    expect((await storage.load('online:a')).visibleGroupIds, isEmpty);
  });
  test('初期値は空で既定グループも未設定とする', () async {
    final value = await storage.load('online:account');
    expect(value.visibleGroupIds, isEmpty);
    expect(value.defaultGroupId, isNull);
    expect(value.hasSavedSettings, isFalse);
  });
  test('表示対象と非表示の既定グループを利用者・モードごとに分けて保存する', () async {
    await storage.save(
      'online:a',
      CalendarGroupSettings(
        visibleGroupIds: {'family', 'friends'},
        defaultGroupId: 'private',
      ),
    );
    await storage.save(
      'offline:a',
      CalendarGroupSettings(visibleGroupIds: {'local'}),
    );
    final value = await storage.load('online:a');
    expect(value.visibleGroupIds, {'family', 'friends'});
    expect(value.defaultGroupId, 'private');
    expect((await storage.load('online:b')).visibleGroupIds, isEmpty);
    expect((await storage.load('offline:a')).visibleGroupIds, {'local'});
    await storage.save('online:a', CalendarGroupSettings());
    expect((await storage.load('online:a')).defaultGroupId, isNull);
    expect((await storage.load('online:a')).hasSavedSettings, isTrue);
  });
}
