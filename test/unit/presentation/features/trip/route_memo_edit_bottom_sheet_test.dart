import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/route_segment_detail_dto.dart';
import 'package:memora/presentation/features/trip/route_memo_edit_bottom_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    RouteSegmentDetailDto initialDetail = const RouteSegmentDetailDto.empty(),
    required ValueChanged<RouteSegmentDetailDto> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteMemoEditBottomSheet(
            initialDetail: initialDetail,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RouteMemoEditBottomSheet', () {
    testWidgets('初期値が入力欄に反映されること', (tester) async {
      final initial = RouteSegmentDetailDto(
        polyline: [],
        distanceMeters: 0,
        durationSeconds: 1200,
        instructions: ['徒歩で移動', 'バスで移動'],
      );

      await pumpSheet(tester, initialDetail: initial, onChanged: (_) {});

      final durationField = tester.widget<TextField>(
        find.byKey(const Key('other_route_duration_field')),
      );
      final instructionField = tester.widget<TextField>(
        find.byKey(const Key('other_route_instructions_field')),
      );

      expect(durationField.controller?.text, '20');
      expect(instructionField.controller?.text, '徒歩で移動\nバスで移動');
    });

    testWidgets('フォーカスが外れたタイミングで入力値が正規化されて通知されること', (tester) async {
      final changes = <RouteSegmentDetailDto>[];

      await pumpSheet(tester, onChanged: changes.add);

      final durationFinder = find.byKey(
        const Key('other_route_duration_field'),
      );
      final instructionFinder = find.byKey(
        const Key('other_route_instructions_field'),
      );

      await tester.tap(durationFinder);
      await tester.enterText(durationFinder, '0015');
      await tester.pump();

      await tester.tap(instructionFinder);
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.last.durationSeconds, 900);
      expect(changes.last.instructions, isEmpty);

      await tester.enterText(instructionFinder, '徒歩で移動  ');
      await tester.pump();

      await tester.tap(durationFinder);
      await tester.pump();

      expect(changes.last.durationSeconds, 900);
      expect(changes.last.instructions, ['徒歩で移動']);
    });

    testWidgets('フォーカスを外さずにウィジェットが破棄されても最新値が通知されること', (tester) async {
      final changes = <RouteSegmentDetailDto>[];

      await pumpSheet(tester, onChanged: changes.add);

      final instructionFinder = find.byKey(
        const Key('other_route_instructions_field'),
      );
      await tester.tap(instructionFinder);
      await tester.enterText(instructionFinder, 'バスで移動');
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(changes, isNotEmpty);
      expect(changes.last.durationSeconds, 0);
      expect(changes.last.instructions, ['バスで移動']);
    });
  });
}
