import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/infrastructure/services/shared_preferences_external_calendar_settings_storage.dart';

void main() {
  test('本人ごとに複数アカウントの表示対象を保存し再読込・解除する', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = SharedPreferencesExternalCalendarSettingsStorage();
    final connections = [
      ExternalCalendarConnection(
        account: const ExternalCalendarAccount(
          id: 'first',
          email: 'first@example.com',
        ),
        calendarIds: {'a', 'b'},
      ),
      ExternalCalendarConnection(
        account: const ExternalCalendarAccount(
          id: 'second',
          email: 'second@example.com',
        ),
        calendarIds: {'c'},
      ),
    ];
    await storage.save('owner', connections);
    expect(await storage.load('other'), isEmpty);
    final restored = await storage.load('owner');
    expect(restored.map((v) => v.account.id), ['first', 'second']);
    expect(restored.map((v) => v.calendarIds), [
      {'a', 'b'},
      {'c'},
    ]);
    await storage.save('other', [connections.first]);
    await storage.remove('owner');
    expect(await storage.load('owner'), isEmpty);
    expect((await storage.load('other')).single.account.id, 'first');
  });

  test('既存の単一アカウントの連携設定と表示対象も引き継ぐ', () async {
    SharedPreferences.setMockInitialValues({
      'external_calendar_owner': jsonEncode({
        'accountId': 'google',
        'email': 'me@example.com',
        'calendarIds': ['a', 'b'],
      }),
    });
    const storage = SharedPreferencesExternalCalendarSettingsStorage();
    final restored = await storage.load('owner');
    expect(restored.single.account.id, 'google');
    expect(restored.single.calendarIds, {'a', 'b'});
  });
}
