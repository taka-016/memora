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
      const initialValue = TripEntryDto(
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
      const initialValue = TripEntryDto(
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

    testWidgets('訪問場所ボタンから旅行のlocationsマップを単独表示すること', (
      WidgetTester tester,
    ) async {
      const initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );
      const locations = [
        LocationDto(
          id: 'location-1',
          tripId: 'trip-id',
          groupId: 'group-id',
          name: '東京駅',
          latitude: 35.681236,
          longitude: 139.767125,
        ),
      ];

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              locations: locations,
              isTestEnvironment: true,
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              onLocationDeleted: (_) async {},
              onLocationCreated: (_) async => locations.first,
            ),
          ),
        ),
      );

      final taskButton = find.widgetWithText(ElevatedButton, 'タスク');
      await tester.ensureVisible(taskButton);

      expect(find.widgetWithText(ElevatedButton, '訪問場所'), findsOneWidget);
      expect(find.byKey(const Key('trip_locations_map')), findsNothing);
      expect(find.byKey(const Key('map_view')), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, '訪問場所'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('trip_locations_expanded_map')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('親からvalueが同期されたときはonChangedを発火しないこと', (
      WidgetTester tester,
    ) async {
      var currentValue = const TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '初期旅行',
        memo: '初期メモ',
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
  });
}
