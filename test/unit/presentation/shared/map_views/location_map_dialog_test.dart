import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/map_views/location_map_dialog.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

void main() {
  group('LocationMapDialog', () {
    testWidgets('共通のマップダイアログを表示して閉じられること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) {
                        return const LocationMapDialog(
                          dialogKey: Key('location_map_dialog'),
                          mapViewType: MapViewType.placeholder,
                          locations: [],
                        );
                      },
                    );
                  },
                  child: const Text('開く'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('location_map_dialog')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('map_view')), findsOneWidget);

      await tester.tap(find.byTooltip('閉じる'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('location_map_dialog')),
        findsNothing,
      );
    });
  });
}
