import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_locations_by_group_id_usecase.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import 'map_screen_test.mocks.dart';

@GenerateMocks([GetGroupsWithMembersUsecase, GetLocationsByGroupIdUsecase])
void main() {
  const testMember = MemberDto(id: 'test-member-id', displayName: 'テストメンバー');

  group('MapScreen', () {
    late MockGetGroupsWithMembersUsecase mockGetGroupsWithMembersUsecase;
    late MockGetLocationsByGroupIdUsecase mockGetLocationsByGroupIdUsecase;

    setUp(() {
      mockGetGroupsWithMembersUsecase = MockGetGroupsWithMembersUsecase();
      mockGetLocationsByGroupIdUsecase = MockGetLocationsByGroupIdUsecase();
      when(
        mockGetGroupsWithMembersUsecase.execute(testMember),
      ).thenAnswer((_) async => const []);
      when(
        mockGetLocationsByGroupIdUsecase.execute(any),
      ).thenAnswer((_) async => const []);
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          getGroupsWithMembersUsecaseProvider.overrideWithValue(
            mockGetGroupsWithMembersUsecase,
          ),
          getLocationsByGroupIdUsecaseProvider.overrideWithValue(
            mockGetLocationsByGroupIdUsecase,
          ),
          currentMemberNotifierProvider.overrideWith(
            () => FakeCurrentMemberNotifier.loaded(testMember),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: MapScreen(isTestEnvironment: true)),
        ),
      );
    }

    testWidgets('MapViewが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PlaceholderMapView), findsOneWidget);
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
    });

    testWidgets('locations取得後の初回のみ1件目のlocationを選択してボトムシートを表示する', (
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getGroupsWithMembersUsecaseProvider.overrideWithValue(
              mockGetGroupsWithMembersUsecase,
            ),
            getLocationsByGroupIdUsecaseProvider.overrideWithValue(
              mockGetLocationsByGroupIdUsecase,
            ),
            currentMemberNotifierProvider.overrideWith(
              () => FakeCurrentMemberNotifier.loaded(testMember),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: MapScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LocationDetailBottomSheet), findsOneWidget);
      expect(find.text('大阪駅'), findsOneWidget);
      expect(find.text('首里城'), findsNothing);
    });
  });
}
