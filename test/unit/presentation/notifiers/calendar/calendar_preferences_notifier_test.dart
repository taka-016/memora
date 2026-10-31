import 'dart:async';

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
  for (final firstFails in [false, true]) {
    test('連続入力を順に保存し途中の保存失敗$firstFailsでも最後の値を保持する', () async {
      final storage = MockCalendarDefaultDurationStorage();
      when(storage.load()).thenAnswer((_) async => 60);
      final firstSave = Completer<void>();
      when(storage.save(15)).thenAnswer((_) => firstSave.future);
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
      final notifier = container.read(
        calendarPreferencesNotifierProvider.notifier,
      );
      final first = notifier.save(15);
      final second = notifier.save(30);
      final last = notifier.save(45);
      verifyNever(storage.save(30));
      verifyNever(storage.save(45));
      if (firstFails) {
        firstSave.completeError(TestException('保存失敗'));
      } else {
        firstSave.complete();
      }
      expect(await Future.wait([first, second, last]), [
        !firstFails,
        true,
        true,
      ]);
      expect(
        container.read(calendarPreferencesNotifierProvider).value!.minutes,
        45,
      );
      verifyInOrder([storage.save(15), storage.save(30), storage.save(45)]);
    });
  }

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
