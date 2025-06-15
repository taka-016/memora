import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:memora/presentation/google_map_screen.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/presentation/widgets/google_map_widget.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class MockCurrentLocationService extends Mock implements CurrentLocationService {}

class MockPinRepository extends Mock implements PinRepository {}

void main() {
  group('GoogleMapScreen', () {
    late MockCurrentLocationService mockLocationService;
    late MockPinRepository mockPinRepository;

    setUp(() {
      mockLocationService = MockCurrentLocationService();
      mockPinRepository = MockPinRepository();
    });

    testWidgets('GoogleMapScreenが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GoogleMapScreen(
            locationService: mockLocationService,
            pinRepository: mockPinRepository,
          ),
        ),
      );

      // AppBarタイトル確認
      expect(find.text('Googleマップ'), findsOneWidget);
      // GoogleMapWidgetが表示されることを確認
      expect(find.byType(GoogleMapWidget), findsOneWidget);
    });

    testWidgets('初期ピンが設定された状態で表示される', (WidgetTester tester) async {
      final initialPins = [Pin(id: '1', pinId: '1', latitude: 10, longitude: 10)];
      
      await tester.pumpWidget(
        MaterialApp(
          home: GoogleMapScreen(
            initialPins: initialPins,
            locationService: mockLocationService,
            pinRepository: mockPinRepository,
          ),
        ),
      );

      expect(find.byType(GoogleMapWidget), findsOneWidget);
    });

    testWidgets('ナビゲーション経由でGoogleMapScreenが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(tester.element(find.byType(ElevatedButton))).push(
                    MaterialPageRoute(
                      builder: (_) => GoogleMapScreen(
                        pinRepository: mockPinRepository,
                      ),
                    ),
                  );
                },
                child: const Text('マップ表示'),
              ),
            ),
          ),
        ),
      );

      // 「マップ表示」ボタンをタップ
      await tester.tap(find.text('マップ表示'));
      await tester.pumpAndSettle();

      // AppBarタイトル確認
      expect(find.text('Googleマップ'), findsOneWidget);
      // GoogleMapWidgetが表示されることを確認
      expect(find.byType(GoogleMapWidget), findsOneWidget);
    });
  });
}
