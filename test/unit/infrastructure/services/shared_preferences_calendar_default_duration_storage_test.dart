import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_default_duration_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('初期値は60分で変更は端末内に永続化する', () async {
    const storage = SharedPreferencesCalendarDefaultDurationStorage();
    expect(await storage.load(), 60);
    await storage.save(90);
    expect(
      await const SharedPreferencesCalendarDefaultDurationStorage().load(),
      90,
    );
    await expectLater(storage.save(0), throwsArgumentError);
  });
}
