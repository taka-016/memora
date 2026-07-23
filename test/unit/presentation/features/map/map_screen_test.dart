import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import '../../../../helpers/test_exception.dart';
import 'map_screen_test.mocks.dart';

@GenerateMocks([
  GetGroupsWithMembersUsecase,
  GetLocationsByGroupIdUsecase,
  GetTripEntriesUsecase,
  GetTripEntryByIdUsecase,
  UpdateTripEntryUsecase,
])
void main() {
  const testMember = MemberDto(id: 'test-member-id', displayName: 'テストメンバー');

  group('MapScreen', () {
    late MockGetGroupsWithMembersUsecase mockGetGroupsWithMembersUsecase;
    late MockGetLocationsByGroupIdUsecase mockGetLocationsByGroupIdUsecase;
    late MockGetTripEntriesUsecase mockGetTripEntriesUsecase;
    late MockGetTripEntryByIdUsecase mockGetTripEntryByIdUsecase;
    late MockUpdateTripEntryUsecase mockUpdateTripEntryUsecase;

    setUp(() {
      mockGetGroupsWithMembersUsecase = MockGetGroupsWithMembersUsecase();
      mockGetLocationsByGroupIdUsecase = MockGetLocationsByGroupIdUsecase();
      mockGetTripEntriesUsecase = MockGetTripEntriesUsecase();
      mockGetTripEntryByIdUsecase = MockGetTripEntryByIdUsecase();
      mockUpdateTripEntryUsecase = MockUpdateTripEntryUsecase();
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const []);
      when(
        mockGetLocationsByGroupIdUsecase.execute(any),
      ).thenAnswer((_) async => const []);
      when(
        mockGetTripEntriesUsecase.executeByGroupId(any),
      ).thenAnswer((_) async => const []);
      when(
        mockGetTripEntryByIdUsecase.execute(any),
      ).thenAnswer((_) async => null);
    });

    Widget buildTestWidget({bool isTestEnvironment = true}) {
      return ProviderScope(
        overrides: [
          getGroupsWithMembersUsecaseProvider.overrideWithValue(
            mockGetGroupsWithMembersUsecase,
          ),
          getLocationsByGroupIdUsecaseProvider.overrideWithValue(
            mockGetLocationsByGroupIdUsecase,
          ),
          getMapTripEntriesUsecaseProvider.overrideWithValue(
            mockGetTripEntriesUsecase,
          ),
          getTripEntryByIdUsecaseProvider.overrideWithValue(
            mockGetTripEntryByIdUsecase,
          ),
          updateTripEntryUsecaseProvider.overrideWithValue(
            mockUpdateTripEntryUsecase,
          ),
          currentMemberNotifierProvider.overrideWith(
            () => FakeCurrentMemberNotifier.loaded(testMember),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: MapScreen(isTestEnvironment: isTestEnvironment)),
        ),
      );
    }

    testWidgets('MapViewが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PlaceholderMapView), findsOneWidget);
    });

    testWidgets('地図は上端に余白を追加せずAndroidのナビゲーション領域を避けて表示する', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final mapRect = tester.getRect(find.byKey(const Key('map_view')));

      expect(mapRect.top, 0);
      expect(mapRect.bottom, 552);
    });

    testWidgets('所属グループごとのlocationsを取得する', (tester) async {
      const groups = [
        GroupDto(id: 'group1', ownerId: 'owner', name: '家族', members: []),
        GroupDto(id: 'group2', ownerId: 'owner', name: '友人', members: []),
      ];
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
          name: '東京駅',
        ),
      ];

      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => groups);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => locations);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group2'),
      ).thenAnswer((_) async => const []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      verify(mockGetGroupsWithMembersUsecase.execute(testMember)).called(1);
      verify(mockGetLocationsByGroupIdUsecase.execute('group1')).called(1);
      verify(mockGetLocationsByGroupIdUsecase.execute('group2')).called(1);
      verify(mockGetTripEntriesUsecase.executeByGroupId('group1')).called(1);
      verify(mockGetTripEntriesUsecase.executeByGroupId('group2')).called(1);
    });

    testWidgets('locations取得後の初回のみ1件目のlocationへカメラ移動しボトムシートは表示しない', (
      tester,
    ) async {
      const groups = [
        GroupDto(id: 'group1', ownerId: 'owner', name: '家族', members: []),
      ];
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅',
        ),
        LocationDto(
          id: 'location2',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 26.217,
          longitude: 127.719,
          name: '首里城',
        ),
      ];

      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => groups);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => locations);

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      final initialPosition = googleMap.initialCameraPosition;

      expect(initialPosition.target.latitude, 34.6937);
      expect(initialPosition.target.longitude, 135.5023);
      expect(find.byType(LocationDetailBottomSheet), findsNothing);
      expect(find.text('大阪駅'), findsNothing);
      expect(find.text('首里城'), findsNothing);
    });

    testWidgets('同一座標のlocationsはピンと左右移動の対象を1件にまとめる', (tester) async {
      const groups = [
        GroupDto(id: 'group1', ownerId: 'owner', name: '家族', members: []),
      ];
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅',
        ),
        LocationDto(
          id: 'location2',
          tripId: 'trip2',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅2回目',
        ),
        LocationDto(
          id: 'location3',
          tripId: 'trip3',
          groupId: 'group1',
          latitude: 26.217,
          longitude: 127.719,
          name: '首里城',
        ),
      ];

      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => groups);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => locations);

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));

      expect(googleMap.markers, hasLength(2));
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        containsAll(['location1', 'location3']),
      );
      expect(
        googleMap.markers.map((marker) => marker.markerId.value),
        isNot(contains('location2')),
      );

      final firstMarker = googleMap.markers.singleWhere(
        (marker) => marker.markerId.value == 'location1',
      );
      firstMarker.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.text('大阪駅'), findsOneWidget);

      await tester.tap(find.byKey(const Key('location_detail_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('大阪駅2回目'), findsNothing);
      expect(find.text('首里城'), findsOneWidget);
    });

    testWidgets('選択したピンと同一座標のlocationsに紐づく旅行だけを一覧表示する', (tester) async {
      const group = GroupDto(
        id: 'group1',
        ownerId: 'owner',
        name: '家族',
        members: [],
      );
      const locations = [
        LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 26.217,
          longitude: 127.719,
          name: '首里城',
        ),
        LocationDto(
          id: 'location2',
          tripId: 'trip2',
          groupId: 'group1',
          latitude: 26.217,
          longitude: 127.719,
          name: '首里城2回目',
        ),
        LocationDto(
          id: 'location3',
          tripId: 'trip3',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
          name: '東京駅',
        ),
      ];
      final trips = [
        TripEntryDto(
          id: 'trip1',
          groupId: 'group1',
          year: 2023,
          name: '沖縄旅行2023',
          startDate: DateTime(2023, 4),
        ),
        TripEntryDto(
          id: 'trip2',
          groupId: 'group1',
          year: 2024,
          name: '沖縄旅行2024',
          startDate: DateTime(2024, 5),
        ),
        TripEntryDto(
          id: 'trip3',
          groupId: 'group1',
          year: 2024,
          name: '東京旅行',
          startDate: DateTime(2024, 6),
        ),
      ];
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const [group]);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => locations);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group1'),
      ).thenAnswer((_) async => trips);

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.markers
          .singleWhere((marker) => marker.markerId.value == 'location1')
          .onTap
          ?.call();
      await tester.pumpAndSettle();

      expect(find.text('沖縄旅行2023'), findsOneWidget);
      expect(find.text('沖縄旅行2024'), findsOneWidget);
      expect(find.text('東京旅行'), findsNothing);
    });

    testWidgets('旅行取得失敗時はピンのボトムシートにエラーを表示する', (tester) async {
      const group = GroupDto(
        id: 'group1',
        ownerId: 'owner',
        name: '家族',
        members: [],
      );
      const location = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 26.217,
        longitude: 127.719,
        name: '首里城',
      );
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const [group]);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => const [location]);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group1'),
      ).thenThrow(TestException('取得失敗'));

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.markers.single.onTap?.call();
      await tester.pumpAndSettle();

      expect(find.text('旅行情報の取得に失敗しました'), findsOneWidget);
    });

    testWidgets('別グループの旅行取得失敗時も取得済みグループの旅行を表示する', (tester) async {
      const groups = [
        GroupDto(id: 'group1', ownerId: 'owner', name: '家族', members: []),
        GroupDto(id: 'group2', ownerId: 'owner', name: '友人', members: []),
      ];
      const group1Location = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 26.217,
        longitude: 127.719,
        name: '首里城',
      );
      const group2Location = LocationDto(
        id: 'location2',
        tripId: 'trip2',
        groupId: 'group2',
        latitude: 35.6812,
        longitude: 139.7671,
        name: '東京駅',
      );
      const trip = TripEntryDto(
        id: 'trip1',
        groupId: 'group1',
        year: 2024,
        name: '沖縄旅行2024',
      );
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => groups);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => const [group1Location]);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group2'),
      ).thenAnswer((_) async => const [group2Location]);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group1'),
      ).thenAnswer((_) async => const [trip]);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group2'),
      ).thenThrow(TestException('取得失敗'));

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.markers
          .singleWhere((marker) => marker.markerId.value == 'location1')
          .onTap
          ?.call();
      await tester.pumpAndSettle();

      expect(find.text('沖縄旅行2024'), findsOneWidget);
      expect(find.text('旅行情報の取得に失敗しました'), findsNothing);
    });

    testWidgets('旅行名タップで地図上に旅行編集を開き閉じると選択中の地図へ戻る', (tester) async {
      const group = GroupDto(
        id: 'group1',
        ownerId: 'owner',
        name: '家族',
        members: [],
      );
      const location = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 26.217,
        longitude: 127.719,
        name: '首里城',
      );
      const trip = TripEntryDto(
        id: 'trip1',
        groupId: 'group1',
        year: 2024,
        name: '沖縄旅行2024',
      );
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const [group]);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => const [location]);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group1'),
      ).thenAnswer((_) async => const [trip]);
      when(
        mockGetTripEntryByIdUsecase.execute('trip1'),
      ).thenAnswer((_) async => trip);

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapScreen)),
      );
      container
          .read(navigationNotifierProvider.notifier)
          .selectItem(NavigationItem.mapDisplay);
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.markers.single.onTap?.call();
      await tester.pumpAndSettle();
      await tester.tap(find.text('沖縄旅行2024'));
      await tester.pumpAndSettle();

      expect(find.byType(TripEditModal), findsOneWidget);
      expect(
        container.read(navigationNotifierProvider).selectedItem,
        NavigationItem.mapDisplay,
      );

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(TripEditModal), findsNothing);
      expect(find.text('首里城'), findsOneWidget);
      expect(find.text('沖縄旅行2024'), findsOneWidget);
    });

    testWidgets('旅行名タップ時に旅行が存在しない場合はエラーを表示する', (tester) async {
      const group = GroupDto(
        id: 'group1',
        ownerId: 'owner',
        name: '家族',
        members: [],
      );
      const location = LocationDto(
        id: 'location1',
        tripId: 'trip1',
        groupId: 'group1',
        latitude: 26.217,
        longitude: 127.719,
        name: '首里城',
      );
      const trip = TripEntryDto(
        id: 'trip1',
        groupId: 'group1',
        year: 2024,
        name: '沖縄旅行2024',
      );
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const [group]);
      when(
        mockGetLocationsByGroupIdUsecase.execute('group1'),
      ).thenAnswer((_) async => const [location]);
      when(
        mockGetTripEntriesUsecase.executeByGroupId('group1'),
      ).thenAnswer((_) async => const [trip]);

      await tester.pumpWidget(buildTestWidget(isTestEnvironment: false));
      await tester.pumpAndSettle();
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.markers.single.onTap?.call();
      await tester.pumpAndSettle();
      await tester.tap(find.text('沖縄旅行2024'));
      await tester.pumpAndSettle();

      expect(find.text('指定された旅行が見つかりませんでした'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapScreen)),
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).destination,
        const GroupTimelineGroupListDestination(),
      );
    });
  });
}
