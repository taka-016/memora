import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/queries/trip/pin_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import 'map_screen_test.mocks.dart';

@GenerateMocks([GroupQueryService, LocationQueryService, PinQueryService])
void main() {
  const testMember = MemberDto(id: 'test-member-id', displayName: 'テストメンバー');
  const testGroup = GroupDto(
    id: 'group1',
    ownerId: 'owner1',
    name: '家族',
    members: [
      GroupMemberDto(
        groupId: 'group1',
        memberId: 'test-member-id',
        displayName: 'テストメンバー',
        isAdministrator: true,
      ),
    ],
  );

  group('MapScreen', () {
    testWidgets('MapViewが表示される', (tester) async {
      final mockGroupQueryService = MockGroupQueryService();
      final mockLocationQueryService = MockLocationQueryService();
      final mockPinQueryService = MockPinQueryService();
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockPinQueryService.getPinsByMemberId(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
            locationQueryServiceProvider.overrideWithValue(
              mockLocationQueryService,
            ),
            pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
            currentMemberNotifierProvider.overrideWith(
              () => FakeCurrentMemberNotifier.loaded(testMember),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderMapView), findsOneWidget);
    });

    testWidgets('ログインユーザーのmemberIdで所属グループのlocationsを取得する', (tester) async {
      final mockGroupQueryService = MockGroupQueryService();
      final mockLocationQueryService = MockLocationQueryService();
      final mockPinQueryService = MockPinQueryService();
      final testLocations = [
        const LocationDto(
          id: 'location1',
          tripId: 'trip1',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
          name: '東京駅',
        ),
        const LocationDto(
          id: 'location2',
          tripId: 'trip2',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          name: '大阪駅',
        ),
      ];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          'test-member-id',
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [testGroup]);
      when(
        mockLocationQueryService.getLocationsByGroupId('group1'),
      ).thenAnswer((_) async => testLocations);
      when(
        mockPinQueryService.getPinsByMemberId(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
            locationQueryServiceProvider.overrideWithValue(
              mockLocationQueryService,
            ),
            pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
            currentMemberNotifierProvider.overrideWith(
              () => FakeCurrentMemberNotifier.loaded(testMember),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          'test-member-id',
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
      verify(
        mockLocationQueryService.getLocationsByGroupId('group1'),
      ).called(1);
      verifyNever(mockPinQueryService.getPinsByMemberId(any));
    });
  });
}
