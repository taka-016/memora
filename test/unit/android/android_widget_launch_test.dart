import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _mainPath = 'lib/main.dart';
const _topPagePath = 'lib/presentation/app/top_page.dart';

void main() {
  group('Androidウィジェットからのアプリ起動', () {
    test('表示中の旅行IDを含むURIでMainActivityを起動する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('tripId = itineraryDate.optString("tripId")'));
      expect(source, contains('actionStartActivity<MainActivity>'));
      expect(source, contains('memoraWidget://openTrip?tripId='));
    });

    test('旅程一覧部分のタップでもMainActivityを起動する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('ItineraryList(context, itineraryDate)'));
      expect(source, contains('LazyColumn('));
      expect(
        source,
        contains('Box(modifier = openTripModifier(context, tripId))'),
      );
    });

    test('直近の旅程へ戻るボタンのアクションを送信する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('text = "直近の旅程"'));
      expect(
        source,
        contains('actionRunCallback<RecentItineraryDateAction>()'),
      );
      expect(source, contains('sendAction(context, "recent")'));
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
