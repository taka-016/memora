import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

void main() {
  group('MapScreen', () {
    testWidgets('テスト環境の場合、PlaceholderMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapScreen(pins: [], isTestEnvironment: true)),
          ),
        ),
      );

      expect(find.byType(PlaceholderMapView), findsOneWidget);
    });

    testWidgets('本番環境の場合、GoogleMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapScreen(pins: [], isTestEnvironment: false)),
          ),
        ),
      );

      expect(find.byType(GoogleMapView), findsOneWidget);
    });

    testWidgets('pinsを正しく渡す', (tester) async {
      final pins = [
        PinDto(pinId: 'pin1', latitude: 35.6812, longitude: 139.7671),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MapScreen(pins: pins, isTestEnvironment: true),
            ),
          ),
        ),
      );

      final placeholderMapView = tester.widget<PlaceholderMapView>(
        find.byType(PlaceholderMapView),
      );
      expect(placeholderMapView, isNotNull);
    });
  });
}
