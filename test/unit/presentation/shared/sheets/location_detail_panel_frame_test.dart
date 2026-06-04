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

    testWidgets('場所名を表示専用で表示できる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationDetailPanelFrame(
              panelKey: Key('location_detail_panel'),
              onClose: _noop,
              locationName: '東京駅',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.text('東京駅'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('場所名が空の場合は未設定表示にする', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationDetailPanelFrame(
              panelKey: Key('location_detail_panel'),
              onClose: _noop,
              locationName: '',
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.text('場所名未設定'), findsOneWidget);
    });

    testWidgets('場所名編集時は入力欄を表示して変更を通知する', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationDetailPanelFrame(
              panelKey: const Key('location_detail_panel'),
              onClose: _noop,
              locationName: '東京駅',
              locationNameFieldKey: const Key('location_name_field'),
              onLocationNameChanged: (value) => changedValue = value,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(TextFormField, '東京駅'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('location_name_field')),
        '上野駅',
      );

      expect(changedValue, '上野駅');
    });
  });
}

void _noop() {}
