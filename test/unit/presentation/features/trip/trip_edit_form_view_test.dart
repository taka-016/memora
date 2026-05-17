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
    testWidgets('入力変更とピン削除の結果をまとめてonChangedへ返すこと', (WidgetTester tester) async {
      TripEntryDto? latestValue;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '既存旅行',
        memo: '既存メモ',
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
      expect(latestValue!.name, '更新後の旅行');
      expect(latestValue!.memo, '既存メモ');
      expect(latestValue!.pins, isEmpty);
    });

    testWidgets('タスク管理・訪問場所編集ボタンが親のハンドラを呼ぶこと', (WidgetTester tester) async {
      var taskRequested = 0;
      var mapRequested = 0;
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
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
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'タスク管理'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '編集'));
      await tester.pump();

      expect(taskRequested, 1);
      expect(mapRequested, 1);
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
                        onTaskManagementRequested: () {},
                        onVisitLocationEditRequested: () {},
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
                          pins: [
                            const PinDto(
                              pinId: 'pin-2',
                              tripId: 'trip-id',
                              latitude: 34.6937,
                              longitude: 135.5023,
                              locationName: '大阪駅',
                            ),
                          ],
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
                        onTaskManagementRequested: () {},
                        onVisitLocationEditRequested: () {},
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

    testWidgets('選択中のピンが更新された場合はボトムシートも最新の内容に同期されること', (
      WidgetTester tester,
    ) async {
      final initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-id',
            latitude: 35.681236,
            longitude: 139.767125,
            locationName: '更新前の場所名',
          ),
        ],
      );
      final updatedValue = initialValue.copyWith(
        pins: [
          PinDto(
            pinId: 'pin-1',
            tripId: 'trip-id',
            latitude: 35.681236,
            longitude: 139.767125,
            locationName: '更新後の場所名',
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
              onTaskManagementRequested: () {},
              onVisitLocationEditRequested: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('pinListItem_pin-1')));
      await tester.pumpAndSettle();

      final locationNameFieldBefore = tester.widget<TextFormField>(
        find.byKey(const Key('locationNameField')),
      );
      expect(locationNameFieldBefore.controller!.text, '更新前の場所名');

      await tester.pumpWidget(
        _createApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: updatedValue,
              onChanged: (_) {},
              onTaskManagementRequested: () {},
              onVisitLocationEditRequested: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final locationNameFieldAfter = tester.widget<TextFormField>(
        find.byKey(const Key('locationNameField')),
      );
      expect(locationNameFieldAfter.controller!.text, '更新後の場所名');
    });
  });
}
