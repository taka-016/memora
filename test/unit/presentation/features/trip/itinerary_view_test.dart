import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/services/location_search_service.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/presentation/features/trip/itinerary_view.dart';
import 'package:memora/presentation/shared/dialogs/custom_date_picker_dialog.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 480, height: 720, child: child)),
  );
}

Widget _wrapWithMapApp(Widget child) {
  return ProviderScope(
    overrides: [
      getCurrentLocationUsecaseProvider.overrideWithValue(
        GetCurrentLocationUsecase(_FakeCurrentLocationService()),
      ),
      searchLocationsUsecaseProvider.overrideWithValue(
        SearchLocationsUsecase(_FakeLocationSearchService()),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: SizedBox(width: 480, height: 720, child: child)),
    ),
  );
}

final _uuidV7Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('ItineraryView', () {
    testWidgets('ヘッダーと旅程項目を開始日時順で表示すること', (tester) async {
      final items = [
        ItineraryItemDto(
          id: 'item-no-start',
          tripId: 'trip-1',
          name: '未定',
          memo: '現地で決める',
        ),
        ItineraryItemDto(
          id: 'item-2',
          tripId: 'trip-1',
          name: '首里城観光',
          startDateTime: DateTime(2024, 1, 2, 10),
          endDateTime: DateTime(2024, 1, 2, 12),
          memo: 'チケットを確認',
        ),
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-1',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
          endDateTime: DateTime(2024, 1, 2, 9),
          memo: 'ホテルで朝食',
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: items,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('旅程'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('朝食'), findsOneWidget);
      expect(find.text('08:00 - 09:00'), findsOneWidget);
      expect(find.text('ホテルで朝食'), findsOneWidget);

      final first = tester.getTopLeft(find.text('朝食')).dy;
      final second = tester.getTopLeft(find.text('首里城観光')).dy;
      final last = tester.getTopLeft(find.text('未定')).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(last));
    });

    testWidgets('旅程項目に紐づく場所名を表示すること', (tester) async {
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '首里城',
        latitude: 26.217,
        longitude: 127.719,
      );
      const item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '首里城観光',
        locationId: 'location-1',
        location: location,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [item],
            locations: const [location],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('首里城観光'), findsOneWidget);
      expect(find.text('首里城'), findsOneWidget);
    });

    testWidgets('旅程項目を追加して親へ通知すること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('itinerary_name_field')),
        '朝食',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '追加'));
      await tester.pumpAndSettle();

      expect(lastChanged, hasLength(1));
      expect(_uuidV7Pattern.hasMatch(lastChanged.first.id), isTrue);
      expect(lastChanged.first.tripId, 'trip-1');
      expect(lastChanged.first.name, '朝食');
      expect(lastChanged.first.startDateTime, isNull);
      expect(lastChanged.first.endDateTime, isNull);
      expect(lastChanged.first.memo, isNull);
    });

    testWidgets('追加用フォームは項目名のみ表示されること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('itinerary_name_field')), findsOneWidget);
      expect(find.byKey(const Key('itinerary_start_date_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_start_time_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_end_date_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_end_time_field')), findsNothing);
      expect(find.byKey(const Key('itinerary_memo_field')), findsNothing);
      expect(
        find.byKey(const Key('itinerary_start_datetime_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('itinerary_end_datetime_field')),
        findsNothing,
      );
      expect(find.text('日付を選択'), findsNothing);
      expect(find.text('時間を選択'), findsNothing);
    });

    testWidgets('追加用フォームは項目名と追加ボタンを横並びで表示すること', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final nameField = find.byKey(const Key('itinerary_name_field'));
      final addButton = find.widgetWithText(ElevatedButton, '追加');

      expect(nameField, findsOneWidget);
      expect(addButton, findsOneWidget);
      expect(tester.getCenter(nameField).dy, tester.getCenter(addButton).dy);
      expect(
        tester.getRect(nameField).right,
        lessThan(tester.getRect(addButton).left),
      );
    });

    testWidgets('旅程項目名が未入力の場合は追加できないこと', (tester) async {
      var changeCount = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [],
            onChanged: (_) => changeCount += 1,
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '追加'));
      await tester.pumpAndSettle();

      expect(find.text('旅程項目名を入力してください'), findsOneWidget);
      expect(changeCount, 0);
    });

    testWidgets('旅程項目を編集できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('itinerary_edit_name_field')),
        '朝食変更',
      );
      await tester.enterText(
        find.byKey(const Key('itinerary_edit_memo_field')),
        '予約時間に合わせる',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
      await tester.pumpAndSettle();

      expect(lastChanged, hasLength(1));
      expect(lastChanged.first.id, 'item-1');
      expect(lastChanged.first.name, '朝食変更');
      expect(lastChanged.first.startDateTime, DateTime(2024, 1, 2, 8));
      expect(lastChanged.first.memo, '予約時間に合わせる');
    });

    testWidgets('旅程項目の場所指定を解除して保存できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      final deletedLocations = <LocationDto>[];
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '首里城',
        latitude: 26.217,
        longitude: 127.719,
      );
      const item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '首里城観光',
        locationId: 'location-1',
        location: location,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: const [item],
            locations: const [location],
            onChanged: (updated) => lastChanged = updated,
            onLocationDeleted: (location) async {
              deletedLocations.add(location);
            },
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('itineraryListItem_item-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, '場所を変更'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '指定を解除'), findsOneWidget);
      expect(find.text('首里城'), findsWidgets);

      await tester.tap(find.widgetWithText(OutlinedButton, '指定を解除'));
      await tester.pumpAndSettle();

      expect(deletedLocations, isEmpty);

      final saveButton = find.widgetWithText(ElevatedButton, '保存');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(lastChanged.single.locationId, isNull);
      expect(lastChanged.single.location, isNull);
      expect(deletedLocations, [location]);
    });

    testWidgets('旅程の場所指定マップは単独表示し、場所選択後も閉じないこと', (tester) async {
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '首里城',
        latitude: 26.217,
        longitude: 127.719,
      );
      const item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '首里城観光',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            groupId: 'group-1',
            items: const [item],
            locations: const [location],
            isTestEnvironment: true,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('itineraryListItem_item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '場所を指定'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('itinerary_location_expanded_map')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('itinerary_location_map')), findsNothing);
      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('旅程マップの灰色ピンは確認ボタンで場所変更すること', (tester) async {
      const oldLocation = LocationDto(
        id: 'location-old',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '旧場所',
        latitude: 26.217,
        longitude: 127.719,
      );
      const newLocation = LocationDto(
        id: 'location-new',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '新場所',
        latitude: 26.218,
        longitude: 127.72,
      );
      const item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '観光',
        locationId: 'location-old',
        location: oldLocation,
      );

      await tester.pumpWidget(
        _wrapWithMapApp(
          ItineraryView(
            tripId: 'trip-1',
            groupId: 'group-1',
            items: const [item],
            locations: const [oldLocation, newLocation],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('itineraryListItem_item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '場所を変更'));
      await tester.pumpAndSettle();

      var googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final markersById = {
        for (final marker in googleMap.markers) marker.markerId.value: marker,
      };
      markersById['location-new']!.onTap?.call();
      await tester.pumpAndSettle();

      googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(find.text('新場所'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '新場所'), findsNothing);
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        contains('location-old'),
      );
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        contains('location-new'),
      );
      expect(find.widgetWithText(ElevatedButton, 'この場所を指定する'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'この場所を指定する'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '新場所'), findsOneWidget);
      googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        isNot(contains('location-old')),
      );
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        contains('location-new'),
      );
    });

    testWidgets('旅程マップで場所指定後に取得した場所名を閉じる前に反映すること', (tester) async {
      const item = ItineraryItemDto(id: 'item-1', tripId: 'trip-1', name: '観光');

      await tester.pumpWidget(
        _wrapWithMapApp(
          ItineraryView(
            tripId: 'trip-1',
            groupId: 'group-1',
            items: const [item],
            locations: const [],
            onLocationCreated: (location) async {
              return location.copyWith(name: '取得済み場所');
            },
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('itineraryListItem_item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '場所を指定'));
      await tester.pumpAndSettle();
      tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .onLongPress
          ?.call(const LatLng(35.681236, 139.767125));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '取得済み場所'), findsOneWidget);
    });

    testWidgets('旅程編集内の場所名は表示のみでマップの詳細表示内から手動変更できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      LocationDto? upsertedLocation;
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '首里城',
        latitude: 26.217,
        longitude: 127.719,
      );
      const item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '首里城観光',
        locationId: 'location-1',
        location: location,
      );

      await tester.pumpWidget(
        _wrapWithMapApp(
          ItineraryView(
            tripId: 'trip-1',
            groupId: 'group-1',
            items: const [item],
            locations: const [location],
            onLocationCreated: (location) async {
              upsertedLocation = location;
              return location;
            },
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('itineraryListItem_item-1')));
      await tester.pumpAndSettle();
      expect(find.text('首里城'), findsWidgets);
      expect(find.widgetWithText(TextFormField, '場所名'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, '場所を変更'));
      await tester.pumpAndSettle();
      tester
          .widget<GoogleMap>(find.byType(GoogleMap))
          .markers
          .single
          .onTap
          ?.call();
      await tester.pumpAndSettle();
      final panel = find.byKey(const Key('itinerary_location_detail_panel'));
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
      await tester.enterText(find.widgetWithText(TextFormField, '場所名'), '守礼門');
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('itinerary_location_expanded_map')),
              matching: find.byTooltip('閉じる'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '保存'));
      await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
      await tester.pumpAndSettle();

      expect(upsertedLocation?.id, 'location-1');
      expect(upsertedLocation?.name, '守礼門');
      expect(lastChanged.single.location?.name, '守礼門');
    });

    testWidgets('旅程項目はリスト上の削除ボタンで削除できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      final deleteButton = find.byKey(const Key('delete_itinerary_item-1'));
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(lastChanged, isEmpty);
      expect(find.text('朝食'), findsNothing);
    });

    testWidgets('旅程項目は開始日の年月日ごとに区切って表示すること', (tester) async {
      final items = [
        ItineraryItemDto(id: 'item-no-start', tripId: 'trip-1', name: '未定'),
        ItineraryItemDto(
          id: 'item-3',
          tripId: 'trip-1',
          name: '夕食',
          startDateTime: DateTime(2024, 1, 3, 18),
        ),
        ItineraryItemDto(
          id: 'item-2',
          tripId: 'trip-1',
          name: '昼食',
          startDateTime: DateTime(2024, 1, 2, 12),
        ),
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-1',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: items,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('itinerary_date_group_2024-01-02')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_date_group_2024-01-03')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_date_group_no_start')),
        findsOneWidget,
      );
      expect(find.text('2024/01/02'), findsOneWidget);
      expect(find.text('2024/01/03'), findsOneWidget);
      expect(find.text('開始日未設定'), findsOneWidget);

      final jan2Header = tester.getTopLeft(find.text('2024/01/02')).dy;
      final breakfast = tester.getTopLeft(find.text('朝食')).dy;
      final lunch = tester.getTopLeft(find.text('昼食')).dy;
      final jan3Header = tester.getTopLeft(find.text('2024/01/03')).dy;
      final dinner = tester.getTopLeft(find.text('夕食')).dy;
      final noStartHeader = tester.getTopLeft(find.text('開始日未設定')).dy;
      final undecided = tester.getTopLeft(find.text('未定')).dy;

      expect(jan2Header, lessThan(breakfast));
      expect(breakfast, lessThan(lunch));
      expect(lunch, lessThan(jan3Header));
      expect(jan3Header, lessThan(dinner));
      expect(dinner, lessThan(noStartHeader));
      expect(noStartHeader, lessThan(undecided));
    });

    testWidgets('開始日グループを折りたたみ展開できること', (tester) async {
      final items = [
        ItineraryItemDto(
          id: 'item-3',
          tripId: 'trip-1',
          name: '夕食',
          startDateTime: DateTime(2024, 1, 3, 18),
        ),
        ItineraryItemDto(
          id: 'item-2',
          tripId: 'trip-1',
          name: '昼食',
          startDateTime: DateTime(2024, 1, 2, 12),
        ),
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-1',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: items,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('toggle_itinerary_date_group_2024-01-02')),
      );
      await tester.pumpAndSettle();

      expect(find.text('2024/01/02'), findsOneWidget);
      expect(find.text('朝食'), findsNothing);
      expect(find.text('昼食'), findsNothing);
      expect(find.text('夕食'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('toggle_itinerary_date_group_2024-01-02')),
      );
      await tester.pumpAndSettle();

      expect(find.text('朝食'), findsOneWidget);
      expect(find.text('昼食'), findsOneWidget);
      expect(find.text('夕食'), findsOneWidget);
    });

    testWidgets('旅程項目は時刻を項目名の上に同じフォントサイズで表示すること', (tester) async {
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final timeFinder = find.text('08:00 - 09:00');
      final nameFinder = find.text('朝食');
      final timeTextStyle = DefaultTextStyle.of(
        tester.element(timeFinder),
      ).style;
      final nameTextStyle = DefaultTextStyle.of(
        tester.element(nameFinder),
      ).style;

      expect(timeFinder, findsOneWidget);
      expect(nameFinder, findsOneWidget);
      expect(
        tester.getTopLeft(timeFinder).dy,
        lessThan(tester.getTopLeft(nameFinder).dy),
      );
      expect(timeTextStyle.fontSize, nameTextStyle.fontSize);
    });

    testWidgets('旅程項目の時刻は開始日を表示せず終了日が開始日と異なる場合だけ終了日を表示すること', (tester) async {
      final items = [
        ItineraryItemDto(
          id: 'same-day',
          tripId: 'trip-1',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 8),
          endDateTime: DateTime(2024, 1, 2, 9),
        ),
        ItineraryItemDto(
          id: 'next-day',
          tripId: 'trip-1',
          name: '夜行移動',
          startDateTime: DateTime(2024, 1, 2, 23),
          endDateTime: DateTime(2024, 1, 3, 1),
        ),
      ];

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: items,
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('08:00 - 09:00'), findsOneWidget);
      expect(find.text('23:00 - 01/03 01:00'), findsOneWidget);
      expect(find.text('01/02 08:00 - 01/02 09:00'), findsNothing);
      expect(find.text('01/02 23:00 - 01/03 01:00'), findsNothing);
    });

    testWidgets('編集ボトムシートはタイトルと削除操作なしでキャンセル・保存操作を表示すること', (tester) async {
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('itinerary_edit_bottom_sheet_handle')),
        findsOneWidget,
      );
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '保存'), findsOneWidget);
      expect(find.text('旅程編集'), findsNothing);
      expect(find.widgetWithText(TextButton, '削除'), findsNothing);
    });

    testWidgets('編集ボトムシートはAndroidのナビゲーション領域を避ける下余白を持つこと', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      final contentPadding = tester.widget<Padding>(
        find.byKey(const Key('itinerary_edit_bottom_sheet_content_padding')),
      );

      expect(
        contentPadding.padding,
        const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 64),
      );
    });

    testWidgets('編集用の開始日時と終了日時は日付・時刻選択フィールドで初期表示されること', (tester) async {
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('itinerary_edit_start_date_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_start_time_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_date_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_time_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('itinerary_edit_start_datetime_field')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('itinerary_edit_end_datetime_field')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('itinerary_edit_bottom_sheet')),
          matching: find.text('2024/01/02'),
        ),
        findsNWidgets(2),
      );
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
    });

    testWidgets('開始日時と終了日時をクリアして保存できること', (tester) async {
      List<ItineraryItemDto> lastChanged = [];
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            items: [item],
            onChanged: (updated) => lastChanged = updated,
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('itinerary_edit_start_date_field')),
          matching: find.byKey(
            const Key('itinerary_edit_start_datetime_clear_button'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('itinerary_edit_end_date_field')),
          matching: find.byKey(
            const Key('itinerary_edit_end_datetime_clear_button'),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('itinerary_edit_start_datetime_clear_button')),
      );
      await tester.tap(
        find.byKey(const Key('itinerary_edit_end_datetime_clear_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('日付を選択'), findsNWidgets(2));
      expect(find.text('時間を選択'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ElevatedButton, '保存'));
      await tester.pumpAndSettle();

      expect(lastChanged, hasLength(1));
      expect(lastChanged.first.startDateTime, isNull);
      expect(lastChanged.first.endDateTime, isNull);
    });

    testWidgets('開始日未設定時は旅行開始日の年月でDatePickerを開くこと', (tester) async {
      final item = ItineraryItemDto(id: 'item-1', tripId: 'trip-1', name: '朝食');

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            tripStartDate: DateTime(2024, 7),
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('itinerary_edit_start_date_field')),
      );
      await tester.pumpAndSettle();

      final dialog = tester.widget<CustomDatePickerDialog>(
        find.byType(CustomDatePickerDialog),
      );
      expect(dialog.initialDate.year, 2024);
      expect(dialog.initialDate.month, 7);
    });

    testWidgets('終了日未設定かつ開始日未設定時は旅行開始日の年月でDatePickerを開くこと', (tester) async {
      final item = ItineraryItemDto(id: 'item-1', tripId: 'trip-1', name: '朝食');

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            tripStartDate: DateTime(2024, 7),
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('itinerary_edit_end_date_field')));
      await tester.pumpAndSettle();

      final dialog = tester.widget<CustomDatePickerDialog>(
        find.byType(CustomDatePickerDialog),
      );
      expect(dialog.initialDate.year, 2024);
      expect(dialog.initialDate.month, 7);
    });

    testWidgets('終了日未設定かつ開始日設定済み時は開始日の年月でDatePickerを開くこと', (tester) async {
      final item = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '朝食',
        startDateTime: DateTime(2024, 8, 3, 10),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          ItineraryView(
            tripId: 'trip-1',
            tripStartDate: DateTime(2024, 7),
            items: [item],
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      final listItem = find.byKey(const Key('itineraryListItem_item-1'));
      await tester.ensureVisible(listItem);
      await tester.tap(listItem);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('itinerary_edit_end_date_field')));
      await tester.pumpAndSettle();

      final dialog = tester.widget<CustomDatePickerDialog>(
        find.byType(CustomDatePickerDialog),
      );
      expect(dialog.initialDate.year, 2024);
      expect(dialog.initialDate.month, 8);
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
