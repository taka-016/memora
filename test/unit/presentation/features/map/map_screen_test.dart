import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_auth_notifier.dart';
import 'map_screen_test.mocks.dart';

@GenerateMocks([PinQueryService])
void main() {
  group('MapScreen', () {
    testWidgets('テスト環境の場合、PlaceholderMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => FakeAuthNotifier.unauthenticated(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: true)),
          ),
        ),
      );

      expect(find.byType(PlaceholderMapView), findsOneWidget);
    });

    testWidgets('本番環境の場合、GoogleMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => FakeAuthNotifier.unauthenticated(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: false)),
          ),
        ),
      );

      expect(find.byType(GoogleMapView), findsOneWidget);
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
            authNotifierProvider.overrideWith(
              (ref) => FakeAuthNotifier.authenticated(userId: 'test-member-id'),
            ),
            pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(mockPinQueryService.getPinsByMemberId('test-member-id')).called(1);
    });
  });
}
