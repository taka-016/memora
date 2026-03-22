import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';

Widget _createApp({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('TripEditFormView', () {
    testWidgets('入力変更とピン削除の結果をまとめてonChangedへ返すこと', (
      WidgetTester tester,
    ) async {
      TripEntryDto? latestValue;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        tripYear: 2024,
        tripName: '既存旅行',
        tripMemo: '既存メモ',
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-id',
            latitude: 35.681236,
            longitude: 139.767125,
            locationName: '東京駅',
          ),
        ],
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (value) => latestValue = value,
              onTaskManagementRequested: () {},
              onVisitLocationEditRequested: () {},
              onRouteInfoRequested: () {},
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '旅行名'),
        '更新後の旅行',
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(latestValue, isNotNull);
      expect(latestValue!.tripName, '更新後の旅行');
      expect(latestValue!.tripMemo, '既存メモ');
      expect(latestValue!.pins, isEmpty);
    });

    testWidgets('画面切り替え要求を粗いコールバックで通知すること', (
      WidgetTester tester,
    ) async {
      var taskRequested = 0;
      var mapRequested = 0;
      var routeRequested = 0;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        tripYear: 2024,
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-id',
            latitude: 35.681236,
            longitude: 139.767125,
            locationName: '東京駅',
          ),
          PinDto(
            pinId: 'pin-2',
            tripId: 'trip-id',
            latitude: 35.6895,
            longitude: 139.6917,
            locationName: '新宿駅',
          ),
        ],
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (_) {},
              onTaskManagementRequested: () => taskRequested += 1,
              onVisitLocationEditRequested: () => mapRequested += 1,
              onRouteInfoRequested: () => routeRequested += 1,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'タスク管理'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '編集'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '経路情報'));
      await tester.pump();

      expect(taskRequested, 1);
      expect(mapRequested, 1);
      expect(routeRequested, 1);
    });
  });
}
