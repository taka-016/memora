import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/map/map_pin_bottom_sheet.dart';

void main() {
  const location = LocationDto(
    id: 'location-1',
    tripId: 'trip-1',
    groupId: 'group-1',
    name: '首里城',
    latitude: 26.217,
    longitude: 127.719,
  );

  Widget buildTestWidget({
    List<TripEntryDto> trips = const [],
    ValueChanged<TripEntryDto>? onTripTapped,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MapPinBottomSheet(
          location: location,
          trips: trips,
          onTripTapped: onTripTapped ?? (_) {},
          onClose: () {},
        ),
      ),
    );
  }

  group('MapPinBottomSheet', () {
    testWidgets('旅行名と開始年月を一覧表示し未設定値も表示する', (tester) async {
      final trips = [
        TripEntryDto(
          id: 'trip-1',
          groupId: 'group-1',
          year: 2024,
          name: '沖縄旅行2024',
          startDate: DateTime(2024, 5, 1),
        ),
        const TripEntryDto(id: 'trip-2', groupId: 'group-1', year: 2023),
      ];

      await tester.pumpWidget(buildTestWidget(trips: trips));

      expect(find.text('訪問した旅行'), findsOneWidget);
      expect(find.text('沖縄旅行2024'), findsOneWidget);
      expect(find.text('2024年5月'), findsOneWidget);
      expect(find.text('旅行名未設定'), findsOneWidget);
      expect(find.text('開始年月未設定'), findsOneWidget);
    });

    testWidgets('旅行がない場合は空状態を表示する', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('この場所を訪問した旅行はありません'), findsOneWidget);
    });

    testWidgets('旅行が多数ある場合も一覧をスクロールして末尾を確認できる', (tester) async {
      final trips = List.generate(
        10,
        (index) => TripEntryDto(
          id: 'trip-$index',
          groupId: 'group-1',
          year: 2024,
          name: '旅行$index',
        ),
      );

      await tester.pumpWidget(buildTestWidget(trips: trips));

      final list = find.descendant(
        of: find.byKey(const Key('map_pin_trip_list_region')),
        matching: find.byType(Scrollable),
      );
      expect(list, findsOneWidget);

      await tester.scrollUntilVisible(find.text('旅行9'), 100, scrollable: list);

      expect(find.text('旅行9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('旅行名をタップすると対象旅行を通知する', (tester) async {
      final trip = TripEntryDto(
        id: 'trip-1',
        groupId: 'group-1',
        year: 2024,
        name: '沖縄旅行2024',
      );
      TripEntryDto? tappedTrip;

      await tester.pumpWidget(
        buildTestWidget(
          trips: [trip],
          onTripTapped: (value) => tappedTrip = value,
        ),
      );
      await tester.tap(find.text('沖縄旅行2024'));

      expect(tappedTrip, trip);
    });
  });
}
