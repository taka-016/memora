import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/services/calendar_default_duration_storage.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';

import '../../../../helpers/test_exception.dart';
@GenerateNiceMocks([MockSpec<CalendarDefaultDurationStorage>()])
import 'calendar_preferences_notifier_test.mocks.dart';

void main() {
  test('保存失敗時に元の標準時間を保持し再試行で更新する', () async {
    final storage = MockCalendarDefaultDurationStorage();
    when(storage.load()).thenAnswer((_) async => 60);
    final container = ProviderContainer(
      overrides: [
        calendarDefaultDurationStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      calendarPreferencesNotifierProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(calendarPreferencesNotifierProvider.future);
    when(storage.save(90)).thenThrow(TestException('保存失敗'));
    expect(
      await container
          .read(calendarPreferencesNotifierProvider.notifier)
          .save(90),
      isFalse,
    );
    expect(
      container.read(calendarPreferencesNotifierProvider).value!.minutes,
      60,
    );
    when(storage.save(90)).thenAnswer((_) async {});
    expect(
      await container
          .read(calendarPreferencesNotifierProvider.notifier)
          .save(90),
      isTrue,
    );
    expect(
      container.read(calendarPreferencesNotifierProvider).value!.minutes,
      90,
    );
  });
}
