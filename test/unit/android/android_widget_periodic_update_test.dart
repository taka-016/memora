import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pubspecPath = 'pubspec.yaml';
const _backgroundUpdatePath =
    'lib/application/usecases/android_widget/android_widget_background_update.dart';
const _mainPath = 'lib/main.dart';
const _cacheUsecasesPath =
    'lib/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _fallbackSchedulerPath =
    'android/app/src/main/kotlin/com/example/memora/AndroidWidgetUpdateFallbackScheduler.kt';
const _fallbackReceiverPath =
    'android/app/src/main/kotlin/com/example/memora/AndroidWidgetUpdateFallbackReceiver.kt';
const _widgetInfoPath =
    'android/app/src/main/res/xml/itinerary_widget_info.xml';
const _androidManifestPath = 'android/app/src/main/AndroidManifest.xml';

void main() {
  group('AndroidWidgetPeriodicUpdate', () {
    test('workmanagerを依存関係に追加している', () {
      final pubspec = File(_pubspecPath).readAsStringSync();

      expect(pubspec, contains('workmanager:'));
    });

    test('指定した間隔で一意な定期タスクを更新する', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(source, contains('registerPeriodicTask'));
      expect(
        source,
        contains('existingWorkPolicy: ExistingPeriodicWorkPolicy.update'),
      );
      expect(source, contains('frequency: frequency'));
      expect(source, contains('memora_android_widget_periodic_update'));
    });

    test('ネットワーク接続時のみバックグラウンド更新を実行する', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(source, contains('Constraints('));
      expect(source, contains('networkType: NetworkType.connected'));
    });

    test('検証用の短間隔One-offタスクを登録しない', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(source, isNot(contains('registerOneOffTask')));
      expect(source, isNot(contains('androidWidgetShortUpdateTaskName')));
      expect(
        source,
        isNot(contains('_registerNextAndroidWidgetShortUpdateTask')),
      );
    });

    test('バックグラウンド更新失敗時も次の通常周期を維持する', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(
        source,
        contains('Future<bool> _refreshAndroidWidgetFromBackground()'),
      );
      expect(
        source,
        contains('return await _refreshAndroidWidgetFromBackground();'),
      );
      expect(source, isNot(contains('return false;')));
      expect(source, contains('preserveExistingCacheOnEmpty: true'));
    });

    test('Firebase初期化を含むバックグラウンド更新全体を例外処理する', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(
        source,
        contains(
          'Future<bool> _refreshAndroidWidgetFromBackground() async {\n'
          '  try {',
        ),
      );
    });

    test('アプリ起動時に定期更新を初期化する', () {
      final source = File(_mainPath).readAsStringSync();

      expect(source, contains('initializeAndroidWidgetBackgroundUpdate'));
      expect(source, contains('registerAndroidWidgetPeriodicUpdateTask'));
    });

    test('表示対象グループ設定時に定期更新タスクを登録する', () {
      final source = File(_cacheUsecasesPath).readAsStringSync();

      expect(source, contains('RegisterAndroidWidgetPeriodicUpdateTask'));
      expect(source, contains('registerPeriodicUpdateTask'));
    });

    test('Glanceウィジェットの状態を同期できるReceiverを使用する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('HomeWidgetGlanceWidgetReceiver'));
      expect(
        source,
        contains(
          'class ItineraryWidgetReceiver : '
          'HomeWidgetGlanceWidgetReceiver<ItineraryWidget>()',
        ),
      );
    });

    test('Android標準のウィジェット定期更新に依存しない', () {
      final source = File(_widgetInfoPath).readAsStringSync();

      expect(source, contains('android:updatePeriodMillis="0"'));
    });

    test('AlarmManagerで30分間隔の復旧監視を継続する', () {
      final schedulerSource = File(_fallbackSchedulerPath).readAsStringSync();
      final receiverSource = File(_fallbackReceiverPath).readAsStringSync();
      final manifestSource = File(_androidManifestPath).readAsStringSync();

      expect(schedulerSource, contains('AlarmManager'));
      expect(schedulerSource, contains('setInexactRepeating'));
      expect(schedulerSource, contains('FALLBACK_CHECK_INTERVAL_MINUTES'));
      expect(receiverSource, contains('BroadcastReceiver'));
      expect(receiverSource, contains('Intent.ACTION_BOOT_COMPLETED'));
      expect(receiverSource, contains('Intent.ACTION_MY_PACKAGE_REPLACED'));
      expect(
        receiverSource,
        contains('AndroidWidgetUpdateFallbackScheduler.recoverIfOverdue'),
      );
      expect(
        manifestSource,
        contains('android.permission.RECEIVE_BOOT_COMPLETED'),
      );
      expect(manifestSource, contains('.AndroidWidgetUpdateFallbackReceiver'));
    });

    test('アプリを開かなくても期限超過した自動更新タスクをネイティブ側で復旧する', () {
      final widgetSource = File(_itineraryWidgetPath).readAsStringSync();
      final schedulerSource = File(_fallbackSchedulerPath).readAsStringSync();

      expect(widgetSource, contains('override fun onReceive'));
      expect(
        widgetSource,
        contains('HomeWidgetPlugin.TRIGGERED_FROM_HOME_WIDGET'),
      );
      expect(widgetSource, contains('AndroidWidgetUpdateFallbackScheduler'));
      expect(schedulerSource, contains('FlutterSharedPreferences'));
      expect(schedulerSource, contains('memora_widget_last_updated_at'));
      expect(schedulerSource, contains('ExistingWorkPolicy.REPLACE'));
      expect(
        schedulerSource,
        contains('ExistingPeriodicWorkPolicy.CANCEL_AND_REENQUEUE'),
      );
      expect(schedulerSource, contains('BackgroundWorker.DART_TASK_KEY'));
      expect(
        schedulerSource,
        contains('memora_widget_fallback_recovery_enqueued_at'),
      );
      expect(schedulerSource, contains('FALLBACK_RECOVERY_COOLDOWN_MINUTES'));
      expect(
        schedulerSource,
        contains('.setInitialDelay(updateIntervalMinutes, TimeUnit.MINUTES)'),
      );
    });
  });
}
