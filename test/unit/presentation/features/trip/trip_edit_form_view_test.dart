import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';

Widget _createApp({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('TripEditFormView', () {
    testWidgets('入力変更の結果をonChangedへ返すこと', (WidgetTester tester) async {
      TripEntryDto? latestValue;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '既存旅行',
        memo: '既存メモ',
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (value) => latestValue = value,
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '旅行名'),
        '更新後の旅行',
      );
      await tester.pump();

      expect(latestValue, isNotNull);
      expect(latestValue!.name, '更新後の旅行');
      expect(latestValue!.memo, '既存メモ');
    });

    testWidgets('旅程・タスクボタンが親のハンドラを呼ぶこと', (WidgetTester tester) async {
      var itineraryRequested = 0;
      var taskRequested = 0;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (_) {},
              onItineraryManagementRequested: () => itineraryRequested += 1,
              onTaskManagementRequested: () => taskRequested += 1,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '旅程'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'タスク'));
      await tester.pump();

      expect(itineraryRequested, 1);
      expect(taskRequested, 1);
    });

    testWidgets('旅程ボタンとタスクボタンは左から旅程、タスクの順で表示されること', (
      WidgetTester tester,
    ) async {
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
            ),
          ),
        ),
      );

      final itineraryButton = find.widgetWithText(ElevatedButton, '旅程');
      final taskButton = find.widgetWithText(ElevatedButton, 'タスク');

      expect(itineraryButton, findsOneWidget);
      expect(taskButton, findsOneWidget);
      expect(
        tester.getRect(itineraryButton).left,
        lessThan(tester.getRect(taskButton).left),
      );
    });

    testWidgets('親の再buildでonChangedが差し替わった場合は最新のハンドラを呼ぶこと', (
      WidgetTester tester,
    ) async {
      var useUpdatedHandler = false;
      var initialHandlerCallCount = 0;
      var updatedHandlerCallCount = 0;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '既存旅行',
      );

      await tester.pumpWidget(
        _createApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        useUpdatedHandler = true;
                      });
                    },
                    child: const Text('ハンドラ切替'),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 480,
                      child: TripEditFormView(
                        value: initialValue,
                        onChanged: useUpdatedHandler
                            ? (_) => updatedHandlerCallCount += 1
                            : (_) => initialHandlerCallCount += 1,
                        onItineraryManagementRequested: () {},
                        onTaskManagementRequested: () {},
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('ハンドラ切替'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, '旅行名'),
        '更新後の旅行',
      );
      await tester.pump();

      expect(initialHandlerCallCount, 0);
      expect(updatedHandlerCallCount, greaterThan(0));
    });

    testWidgets('親からvalueが同期されたときはonChangedを発火しないこと', (
      WidgetTester tester,
    ) async {
      var currentValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '初期旅行',
        memo: '初期メモ',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );
      final emittedValues = <TripEntryDto>[];

      await tester.pumpWidget(
        _createApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        currentValue = currentValue.copyWith(
                          name: '外部更新後の旅行',
                          memo: '外部更新後のメモ',
                          startDate: DateTime(2024, 2, 1),
                          endDate: DateTime(2024, 2, 3),
                        );
                      });
                    },
                    child: const Text('外部更新'),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 480,
                      child: TripEditFormView(
                        value: currentValue,
                        onChanged: emittedValues.add,
                        onItineraryManagementRequested: () {},
                        onTaskManagementRequested: () {},
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('外部更新'));
      await tester.pump();

      expect(emittedValues, isEmpty);
      expect(find.text('外部更新後の旅行'), findsOneWidget);
      expect(find.text('外部更新後のメモ'), findsOneWidget);
    });

    testWidgets('旅程とタスクボタンの下に旅行のlocationsマップを表示すること', (
      WidgetTester tester,
    ) async {
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        locations: const [
          LocationDto(
            id: 'location-1',
            tripId: 'trip-id',
            groupId: 'group-id',
            latitude: 35.0,
            longitude: 139.0,
            name: 'ホテル',
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
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      final itineraryButton = find.widgetWithText(ElevatedButton, '旅程');
      final taskButton = find.widgetWithText(ElevatedButton, 'タスク');
      final mapView = find.byKey(const Key('trip_locations_map_view'));

      expect(mapView, findsOneWidget);
      expect(
        tester.getRect(mapView).top,
        greaterThan(tester.getRect(itineraryButton).bottom),
      );
      expect(
        tester.getRect(mapView).top,
        greaterThan(tester.getRect(taskButton).bottom),
      );
    });

    testWidgets('旅行locationsマップの長押し結果を新しいlocationとしてonChangedへ返すこと', (
      WidgetTester tester,
    ) async {
      TripEntryDto? latestValue;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              onChanged: (value) => latestValue = value,
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              isTestEnvironment: true,
            ),
          ),
        ),
      );

      final state = tester.state<TripLocationsMapViewState>(
        find.byKey(const Key('trip_locations_map_view')),
      );
      state.debugAddLocationForTest(latitude: 35.0, longitude: 139.0);
      await tester.pump();

      expect(latestValue?.locations, hasLength(1));
      expect(latestValue!.locations!.first.tripId, 'trip-id');
      expect(latestValue!.locations!.first.groupId, 'group-id');
      expect(latestValue!.locations!.first.latitude, 35.0);
      expect(latestValue!.locations!.first.longitude, 139.0);
    });
  });
}
