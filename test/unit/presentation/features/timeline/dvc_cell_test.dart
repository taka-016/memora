import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_point_usage_timeline_row.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

void main() {
  group('DvcPointUsageTimelineRow', () {
    testWidgets('利用データが空の場合、ポイント表示を行わない', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildDvcRowWidget(usages: const [], availableHeight: 100),
      );

      expect(find.textContaining('pt'), findsNothing);
    });

    testWidgets('利用年月と利用ポイントを1行で表示し、メモを2行目に表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildDvcRowWidget(
          usages: [
            DvcPointUsageDto(
              id: '1',
              groupId: 'group1',
              usageYearMonth: DateTime(2024, 8),
              usedPoint: 120,
              memo: '家族旅行',
            ),
          ],
          availableHeight: 100,
          year: 2024,
        ),
      );

      expect(find.text('2024-08  120pt'), findsOneWidget);
      expect(find.text('家族旅行'), findsOneWidget);
    });

    testWidgets('メモは折り返さず、表示しきれない場合は省略表示を設定する', (WidgetTester tester) async {
      const memo = 'とても長いメモですとても長いメモですとても長いメモです';

      await tester.pumpWidget(
        _buildDvcRowWidget(
          usages: [
            DvcPointUsageDto(
              id: '1',
              groupId: 'group1',
              usageYearMonth: DateTime(2024, 8),
              usedPoint: 120,
              memo: memo,
            ),
          ],
          availableHeight: 100,
          availableWidth: 80,
          year: 2024,
        ),
      );

      final memoText = tester.widget<Text>(find.text(memo));
      expect(memoText.maxLines, 1);
      expect(memoText.softWrap, isFalse);
      expect(memoText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('利用可能な高さが小さい場合、省略件数を表示する', (WidgetTester tester) async {
      final usages = List.generate(
        10,
        (index) => DvcPointUsageDto(
          id: '$index',
          groupId: 'group1',
          usageYearMonth: DateTime(2024, index + 1),
          usedPoint: 100 + index,
          memo: 'メモ$index',
        ),
      );

      await tester.pumpWidget(
        _buildDvcRowWidget(usages: usages, availableHeight: 64, year: 2024),
      );

      expect(find.text('2024-01  100pt'), findsOneWidget);
      expect(find.text('メモ0'), findsOneWidget);
      expect(find.textContaining('…他9件'), findsOneWidget);
    });
  });
}

Widget _buildDvcRowWidget({
  required List<DvcPointUsageDto> usages,
  required double availableHeight,
  double availableWidth = 200,
  int year = 2023,
}) {
  final row = const DvcPointUsageTimelineRow(initialHeight: 100);
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return row.buildYearCell(
            context: context,
            rowContext: _rowContext(usages: usages, year: year),
            year: year,
            rowHeight: availableHeight,
            yearColumnWidth: availableWidth,
          );
        },
      ),
    ),
  );
}

TimelineRowContext _rowContext({
  required List<DvcPointUsageDto> usages,
  required int year,
}) {
  return TimelineRowContext(
    groupId: 'group1',
    tripsByYear: const {},
    dvcPointUsagesByYear: {year: usages},
    groupEventsByYear: const {},
    buildMemberLabels:
        ({
          required DateTime? birthday,
          required String? gender,
          required int targetYear,
        }) {
          return const [];
        },
    saveGroupEvent:
        ({
          required currentEvent,
          required groupId,
          required selectedYear,
          required memo,
        }) async {},
  );
}
