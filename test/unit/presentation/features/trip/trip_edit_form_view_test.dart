import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';

Widget _createApp({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

Widget _createMapApp({required Widget child}) {
  return ProviderScope(
    overrides: [
      getCurrentLocationUsecaseProvider.overrideWithValue(
        GetCurrentLocationUsecase(_FakeCurrentLocationService()),
      ),
      searchLocationsUsecaseProvider.overrideWithValue(
        SearchLocationsUsecase(_FakeLocationSearchService()),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
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

    testWidgets('旅行編集マップでピン削除後に表示中マップからピンが消えること', (tester) async {
      const initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      await tester.pumpWidget(
        _createMapApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              locations: const [location],
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              onLocationDeleted: (_) async {},
              onLocationCreated: (location) async => location,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '訪問場所'));
      await tester.pumpAndSettle();
      var googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.markers, hasLength(1));

      googleMap.markers.single.onTap?.call();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '削除'));
      await tester.pumpAndSettle();

      googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.markers, isEmpty);
    });

    testWidgets('旅行編集マップで場所名を入力後に即時反映すること', (tester) async {
      const initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      LocationDto? updatedLocation;

      await tester.pumpWidget(
        _createMapApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              locations: const [location],
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              onLocationDeleted: (_) async {},
              onLocationCreated: (location) async {
                updatedLocation = location;
                return location;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '訪問場所'));
      await tester.pumpAndSettle();
      tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .markers
          .single
          .onTap
          ?.call();
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, '場所名'), '上野駅');
      await tester.pumpAndSettle();

      expect(updatedLocation?.id, 'location-1');
      expect(updatedLocation?.name, '上野駅');
      expect(find.widgetWithText(OutlinedButton, '場所名を更新'), findsNothing);
      expect(find.widgetWithText(TextFormField, '上野駅'), findsOneWidget);
    });

    testWidgets('旅行編集マップのピン詳細で関連する旅程を縦並び表示してスクロールできること', (
      tester,
    ) async {
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      const initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        itineraryItems: [
          ItineraryItemDto(
            id: 'itinerary-1',
            tripId: 'trip-id',
            name: '朝食',
            locationId: 'location-1',
          ),
          ItineraryItemDto(
            id: 'itinerary-2',
            tripId: 'trip-id',
            name: '観光',
            locationId: 'location-1',
          ),
          ItineraryItemDto(
            id: 'itinerary-3',
            tripId: 'trip-id',
            name: '夕食',
            locationId: 'location-1',
          ),
        ],
      );

      await tester.pumpWidget(
        _createMapApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              locations: const [location],
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              onLocationDeleted: (_) async {},
              onLocationCreated: (location) async => location,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '訪問場所'));
      await tester.pumpAndSettle();
      tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .markers
          .single
          .onTap
          ?.call();
      await tester.pumpAndSettle();

      final panel = find.byKey(const Key('trip_location_detail_panel'));
      final scrollView = find.descendant(
        of: panel,
        matching: find.byKey(const Key('trip_location_detail_scroll_view')),
      );
      expect(scrollView, findsOneWidget);
      expect(find.text('関連する旅程'), findsOneWidget);
      expect(find.text('朝食'), findsOneWidget);
      expect(find.text('観光'), findsOneWidget);
      expect(find.text('夕食'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('観光')).dy,
        greaterThan(tester.getTopLeft(find.text('朝食')).dy),
      );
      expect(
        tester.getTopLeft(find.text('夕食')).dy,
        greaterThan(tester.getTopLeft(find.text('観光')).dy),
      );
    });

    testWidgets('旅行編集マップで別ピン選択時に場所名入力欄と閉じるボタン位置を更新すること', (tester) async {
      const initialValue = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
      );
      const firstLocation = LocationDto(
        id: 'location-1',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      const secondLocation = LocationDto(
        id: 'location-2',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '上野駅',
        latitude: 35.713768,
        longitude: 139.777254,
      );

      await tester.pumpWidget(
        _createMapApp(
          child: SizedBox(
            width: 480,
            height: 720,
            child: TripEditFormView(
              value: initialValue,
              locations: const [firstLocation, secondLocation],
              onChanged: (_) {},
              onItineraryManagementRequested: () {},
              onTaskManagementRequested: () {},
              onLocationDeleted: (_) async {},
              onLocationCreated: (location) async => location,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '訪問場所'));
      await tester.pumpAndSettle();
      final markersById = {
        for (final marker
            in tester.widget<GoogleMap>(find.byType(GoogleMap)).markers)
          marker.markerId.value: marker,
      };

      markersById['location-1']!.onTap?.call();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '東京駅'), findsOneWidget);

      markersById['location-2']!.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '上野駅'), findsOneWidget);
      final panel = find.byKey(const Key('trip_location_detail_panel'));
      final nameField = find.descendant(
        of: panel,
        matching: find.byType(TextFormField),
      );
      final closeButton = find
          .descendant(of: panel, matching: find.byTooltip('閉じる'))
          .first;
      expect(
        tester.getTopLeft(closeButton).dy,
        lessThan(tester.getTopLeft(nameField).dy),
      );
    });
  });
}

class _FakeCurrentLocationService implements CurrentLocationService {
  @override
  Future<Coordinate?> getCurrentLocation() async => null;
}

class _FakeLocationSearchService implements LocationSearchService {
  @override
  Future<List<LocationCandidateDto>> searchByKeyword(String keyword) async {
    return const [];
  }
}
