import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _rendererPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidgetRenderer.kt';
const _mainPath = 'lib/main.dart';
const _topPagePath = 'lib/presentation/app/top_page.dart';

void main() {
  group('Androidウィジェットからのアプリ起動', () {
    test('ウィジェットの起動URIをFlutterの自動リンク処理で重複処理しない', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(
        manifest,
        matches(
          RegExp(
            r'android:name="flutter_deeplinking_enabled"\s+android:value="false"',
          ),
        ),
      );
    });

    test('旅行ヘッダーと旅程項目は旅行IDを含む起動URIを使う', () {
      final source = File(_rendererPath).readAsStringSync();
      expect(source, contains('HomeWidgetLaunchIntent.getActivity'));
      expect(source, contains('itineraryTripUri(it.tripId)'));
      expect(source, contains('.authority("openTrip")'));
      expect(source, contains('.appendQueryParameter("tripId", tripId)'));
      expect(
        source,
        contains('setOnClickFillInIntent(R.id.itinerary_item_row'),
      );
      expect(source, contains('data = itineraryTripUri(tripId)'));
    });

    test('表示対象グループが未設定の旅程欄は設定画面を開く', () {
      final source = File(_rendererPath).readAsStringSync();
      expect(source, contains('memoraWidget://openSettings'));
      expect(
        source,
        contains('setOnClickPendingIntent(R.id.itinerary_message'),
      );
    });

    test('直近の旅程へ戻るボタンは操作時点の日付から選択する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();
      final layout = File(
        'android/app/src/main/res/layout/itinerary_widget.xml',
      ).readAsStringSync();
      expect(layout, contains('android:text="直近の旅程"'));
      expect(
        source,
        contains('rememberPendingNavigation(context, cache, current, action)'),
      );
      expect(
        source,
        contains('requestItineraryNavigationRefresh(context, action)'),
      );
      expect(source, contains('ItineraryWidgetData.select(context, target)'));
    });

    test('取得済みの日付一覧の外への操作も追加取得へ接続する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();
      expect(source, contains('target == null || action == "recent"'));
      expect(source, contains('applyPendingNavigation(context, cache)'));
    });

    test('Flutter起動時にウィジェット起動Notifierを初期化する', () {
      final source = File(_mainPath).readAsStringSync();

      expect(source, contains('androidWidgetLaunchNotifierProvider'));
      expect(
        source,
        contains('ref.watch(androidWidgetLaunchNotifierProvider)'),
      );
    });

    test('TopPageはNotifierが解決した遷移要求だけを処理する', () {
      final source = File(_topPagePath).readAsStringSync();

      expect(source, isNot(contains('get_trip_entry_by_id_usecase.dart')));
      expect(source, isNot(contains('get_groups_with_members_usecase.dart')));
      expect(source, contains('resolvePendingLaunch'));
      expect(source, contains('takeResolution'));
    });
  });
}
