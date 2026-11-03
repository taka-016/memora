import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/infrastructure/services/shared_preferences_external_calendar_settings_storage.dart';

void main() {
  test('本人ごとにアカウントと選択を保存し再読込・解除する', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = SharedPreferencesExternalCalendarSettingsStorage();
    final connection = ExternalCalendarConnection(
      account: const ExternalCalendarAccount(
        id: 'google',
        email: 'me@example.com',
      ),
      calendarIds: {'a', 'b'},
    );
    await storage.save('owner', connection);
    expect(await storage.load('other'), isNull);
    final restored = await storage.load('owner');
    expect(restored!.account.id, 'google');
    expect(restored.calendarIds, {'a', 'b'});
    await storage.save(
      'owner',
      ExternalCalendarConnection(
        account: const ExternalCalendarAccount(
          id: 'second',
          email: 'second@example.com',
        ),
      ),
    );
    expect((await storage.load('owner'))!.calendarIds, isEmpty);
    await storage.remove('owner');
    expect(await storage.load('owner'), isNull);
  });
}
