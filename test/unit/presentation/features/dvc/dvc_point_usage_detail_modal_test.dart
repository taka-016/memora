import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';

void main() {
  group('showDvcPointUsageDetailModal', () {
    Widget buildSubject({
      required int selectedYear,
      required List<DvcPointUsageDto> usages,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showDvcPointUsageDetailModal(
                    context: context,
                    selectedYear: selectedYear,
                    usages: usages,
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('利用詳細を既存Key付きで表示できる', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          selectedYear: 2026,
          usages: [
            DvcPointUsageDto(
              id: 'usage-1',
              groupId: 'group-1',
              usageYearMonth: DateTime(2026, 1),
              usedPoint: 30,
              memo: 'メモ1',
            ),
            DvcPointUsageDto(
              id: 'usage-2',
              groupId: 'group-1',
              usageYearMonth: DateTime(2026, 4),
              usedPoint: 60,
            ),
          ],
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dvc_point_usage_detail_dialog_2026')),
        findsOneWidget,
      );
      expect(find.text('DVCポイント利用詳細（2026年）'), findsOneWidget);
      expect(find.text('利用年月: 2026-01'), findsOneWidget);
      expect(find.text('利用ポイント: 30pt'), findsOneWidget);
      expect(find.text('メモ: メモ1'), findsOneWidget);
      expect(find.text('利用年月: 2026-04'), findsOneWidget);
      expect(find.text('利用ポイント: 60pt'), findsOneWidget);
      expect(find.text('メモ: なし'), findsOneWidget);
    });
  });
}
