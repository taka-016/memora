import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/sheets/location_detail_panel_frame.dart';

void main() {
  group('LocationDetailPanelFrame', () {
    testWidgets('閉じるボタンを詳細内容より上の右端に表示する', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationDetailPanelFrame(
              panelKey: const Key('location_detail_panel'),
              onClose: () => closed = true,
              child: const TextField(
                key: Key('location_detail_body'),
                decoration: InputDecoration(labelText: '場所名'),
              ),
            ),
          ),
        ),
      );

      final panel = find.byKey(const Key('location_detail_panel'));
      final closeButton = find
          .descendant(of: panel, matching: find.byTooltip('閉じる'))
          .first;
      final body = find.byKey(const Key('location_detail_body'));

      expect(
        tester.getTopLeft(closeButton).dy,
        lessThan(tester.getTopLeft(body).dy),
      );
      expect(
        tester.getTopLeft(closeButton).dx,
        greaterThan(tester.getTopLeft(body).dx),
      );

      await tester.tap(closeButton);

      expect(closed, isTrue);
    });
  });
}
