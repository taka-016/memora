import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/android_widget/android_widget_background_update.dart';

void main() {
  group('AndroidWidgetBackgroundUpdateRunner', () {
    test('キャッシュ更新が完了しなくてもタイムアウトして次の周期を維持する', () async {
      final refreshCompleter = Completer<void>();
      var updateWidgetCount = 0;
      var notificationCount = 0;
      final stages = <AndroidWidgetBackgroundUpdateStage>[];
      final runner = AndroidWidgetBackgroundUpdateRunner(
        refreshCache: () => refreshCompleter.future,
        updateWidget: () async {
          updateWidgetCount += 1;
        },
        showUpdateFailedNotification: () async {
          notificationCount += 1;
        },
        recordStage: (stage, error, stackTrace) {
          stages.add(stage);
        },
        refreshTimeout: Duration.zero,
        widgetUpdateTimeout: Duration.zero,
        notificationTimeout: Duration.zero,
      );

      final succeeded = await runner.execute();

      expect(succeeded, isTrue);
      expect(updateWidgetCount, 1);
      expect(notificationCount, 1);
      expect(stages, [
        AndroidWidgetBackgroundUpdateStage.started,
        AndroidWidgetBackgroundUpdateStage.failed,
        AndroidWidgetBackgroundUpdateStage.completed,
      ]);
    });

    test('ウィジェット再描画が完了しなくてもタイムアウトして処理を終了する', () async {
      final updateWidgetCompleter = Completer<void>();
      var notificationCount = 0;
      final stages = <AndroidWidgetBackgroundUpdateStage>[];
      final runner = AndroidWidgetBackgroundUpdateRunner(
        refreshCache: () async {},
        updateWidget: () => updateWidgetCompleter.future,
        showUpdateFailedNotification: () async {
          notificationCount += 1;
        },
        recordStage: (stage, error, stackTrace) {
          stages.add(stage);
        },
        refreshTimeout: Duration.zero,
        widgetUpdateTimeout: Duration.zero,
        notificationTimeout: Duration.zero,
      );

      final succeeded = await runner.execute();

      expect(succeeded, isTrue);
      expect(notificationCount, 1);
      expect(stages, [
        AndroidWidgetBackgroundUpdateStage.started,
        AndroidWidgetBackgroundUpdateStage.cacheUpdated,
        AndroidWidgetBackgroundUpdateStage.failed,
        AndroidWidgetBackgroundUpdateStage.completed,
      ]);
    });
  });

  group('AndroidWidgetPeriodicUpdateRegistrar', () {
    test('未完了の実行記録が古い場合は既存タスクを解除して再登録する', () async {
      var cancelCount = 0;
      var registeredFrequency = Duration.zero;
      final registrar = AndroidWidgetPeriodicUpdateRegistrar(
        loadStartedAt: () async => DateTime(2026, 6, 20, 11),
        loadCompletedAt: () async => DateTime(2026, 6, 20, 10),
        cancelPeriodicTask: () async {
          cancelCount += 1;
        },
        registerPeriodicTask: (frequency) async {
          registeredFrequency = frequency;
        },
        now: () => DateTime(2026, 6, 20, 11, 3),
        staleAfter: const Duration(minutes: 2),
      );

      await registrar.execute(const Duration(hours: 1));

      expect(cancelCount, 1);
      expect(registeredFrequency, const Duration(hours: 1));
    });

    test('実行中でも猶予時間内の場合は既存タスクを解除しない', () async {
      var cancelCount = 0;
      final registrar = AndroidWidgetPeriodicUpdateRegistrar(
        loadStartedAt: () async => DateTime(2026, 6, 20, 11),
        loadCompletedAt: () async => DateTime(2026, 6, 20, 10),
        cancelPeriodicTask: () async {
          cancelCount += 1;
        },
        registerPeriodicTask: (_) async {},
        now: () => DateTime(2026, 6, 20, 11, 1),
        staleAfter: const Duration(minutes: 2),
      );

      await registrar.execute(const Duration(hours: 1));

      expect(cancelCount, 0);
    });
  });
}
