import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/trip/select_visit_location_view.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('SelectVisitLocationView', () {
    testWidgets('閉じるアイコンタップでコールバックが呼ばれること', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        buildTestApp(
          SelectVisitLocationView(
            pins: const [],
            selectedPin: null,
            isTestEnvironment: true,
            bottomSheet: const SizedBox.shrink(),
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });

    testWidgets('テスト環境ではプレースホルダーマップが表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SelectVisitLocationView(
            pins: const [],
            selectedPin: null,
            isTestEnvironment: true,
            bottomSheet: const SizedBox.shrink(),
            onClose: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('map_view')), findsOneWidget);
    });

    testWidgets('渡されたボトムシートが表示されること', (tester) async {
      const bottomSheetKey = Key('test_bottom_sheet');

      await tester.pumpWidget(
        buildTestApp(
          SelectVisitLocationView(
            pins: const [],
            selectedPin: null,
            isTestEnvironment: true,
            bottomSheet: const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(key: bottomSheetKey, height: 50, width: 50),
            ),
            onClose: () {},
          ),
        ),
      );

      expect(find.byKey(bottomSheetKey), findsOneWidget);
    });
  });
}
