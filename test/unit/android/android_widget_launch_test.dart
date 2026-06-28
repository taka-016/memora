import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _mainPath = 'lib/main.dart';

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
      expect(
        source,
        contains('LazyColumn(modifier = GlanceModifier.fillMaxWidth())'),
      );
      expect(
        source,
        contains('Box(modifier = openTripModifier(context, tripId))'),
      );
    });

    test('左矢印の上に直近の旅程へ戻るボタンを表示する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('RecentItineraryDateActionRow()'));
      expect(source, contains('RECENT_BUTTON_BOTTOM_SPACE_DP.dp'));
      expect(source, contains('text = "直近の旅程"'));
      expect(
        source,
        contains('actionRunCallback<RecentItineraryDateAction>()'),
      );
      expect(source, contains('sendAction(context, "recent")'));
      expect(
        source,
        isNot(
          contains(
            'contentAlignment = Alignment.TopStart,\n'
            '        ) {\n'
            '            RecentItineraryDateButton()',
          ),
        ),
      );
    });

    test('Flutter起動時にウィジェット起動Notifierを初期化する', () {
      final source = File(_mainPath).readAsStringSync();

      expect(source, contains('androidWidgetLaunchNotifierProvider'));
      expect(
        source,
        contains('ref.watch(androidWidgetLaunchNotifierProvider)'),
      );
    });
  });
}
