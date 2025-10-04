import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';

void main() {
  group('MapScreen', () {
    testWidgets('テスト環境の場合、PlaceholderMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: true)),
          ),
        ),
      );

      expect(find.byType(PlaceholderMapView), findsOneWidget);
    });

    testWidgets('本番環境の場合、GoogleMapViewを表示する', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: MapScreen(isTestEnvironment: false)),
          ),
        ),
      );

      expect(find.byType(GoogleMapView), findsOneWidget);
    });
  });
}
