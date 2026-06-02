import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/map_views/expanded_location_map_dialog.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';

void main() {
  group('ExpandedLocationMapDialog', () {
    testWidgets('共通の拡大マップダイアログを表示して閉じられること', (tester) async {
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
                        return const ExpandedLocationMapDialog(
                          dialogKey: Key('expanded_location_map_dialog'),
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
        find.byKey(const Key('expanded_location_map_dialog')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('map_view')), findsOneWidget);

      await tester.tap(find.byTooltip('閉じる'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('expanded_location_map_dialog')),
        findsNothing,
      );
    });
  });
}
