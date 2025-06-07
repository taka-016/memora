import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_verification/presentation/widgets/google_places_search_bar.dart';

void main() {
  const dummyApiKey = 'dummy';
  group('GooglePlacesSearchBar', () {
    testWidgets('検索バーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GooglePlacesSearchBar(
              apiKey: dummyApiKey,
              onPlaceSelected: null,
            ),
          ),
        ),
      );
      expect(find.byType(GooglePlacesSearchBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('検索結果選択時にコールバックが呼ばれる', (WidgetTester tester) async {
      bool called = false;
      double? lat;
      double? lng;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooglePlacesSearchBar(
              apiKey: dummyApiKey,
              onPlaceSelected: (double latValue, double lngValue) {
                called = true;
                lat = latValue;
                lng = lngValue;
              },
            ),
          ),
        ),
      );
      final state =
          tester.state(find.byType(GooglePlacesSearchBar))
              as GooglePlacesSearchBarState;
      state.widget.onPlaceSelected?.call(35.0, 139.0);
      expect(called, isTrue);
      expect(lat, 35.0);
      expect(lng, 139.0);
    });
  });
}
