import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/queries/trip/pin_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import 'map_screen_test.mocks.dart';

@GenerateMocks([PinQueryService])
void main() {
  const testMember = MemberDto(id: 'test-member-id', displayName: 'テストメンバー');

  group('MapScreen', () {
    testWidgets('MapViewが表示される', (tester) async {
      final mockPinQueryService = MockPinQueryService();
      when(
        mockPinQueryService.getPinsByMemberId(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

    testWidgets('ログインユーザーのmemberIdでPinQueryServiceからpinsを取得する', (tester) async {
      final mockPinQueryService = MockPinQueryService();
      final testPins = [
        const PinDto(
          pinId: 'pin1',
          groupId: 'group1',
          latitude: 35.6812,
          longitude: 139.7671,
          locationName: '東京駅',
        ),
        const PinDto(
          pinId: 'pin2',
          groupId: 'group1',
          latitude: 34.6937,
          longitude: 135.5023,
          locationName: '大阪駅',
        ),
      ];

      when(
        mockPinQueryService.getPinsByMemberId('test-member-id'),
      ).thenAnswer((_) async => testPins);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      verify(mockPinQueryService.getPinsByMemberId('test-member-id')).called(1);
    });
  });
}
