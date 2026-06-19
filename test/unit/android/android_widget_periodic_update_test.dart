import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pubspecPath = 'pubspec.yaml';
const _backgroundUpdatePath =
    'lib/application/usecases/android_widget/android_widget_background_update.dart';
const _mainPath = 'lib/main.dart';
const _cacheUsecasesPath =
    'lib/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';

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

    test('バックグラウンド更新失敗時はWorkManagerへ失敗を返す', () {
      final source = File(_backgroundUpdatePath).readAsStringSync();

      expect(
        source,
        contains('Future<bool> _refreshAndroidWidgetFromBackground()'),
      );
      expect(
        source,
        contains('return await _refreshAndroidWidgetFromBackground();'),
      );
      expect(source, contains('return false;'));
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
  });
}
