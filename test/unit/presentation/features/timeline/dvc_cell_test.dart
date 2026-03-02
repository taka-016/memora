import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_cell.dart';

void main() {
  group('DvcCell', () {
    testWidgets('利用データが空の場合、空のContainerを表示する', (WidgetTester tester) async {
      // Arrange
      final widget = DvcCell(
        usages: const [],
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byType(Container), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.child, isNull);
    });

    testWidgets('利用年月と利用ポイントを1行で表示し、メモを2行目に表示する', (WidgetTester tester) async {
      // Arrange
      final widget = DvcCell(
        usages: [
          DvcPointUsageDto(
            id: '1',
            groupId: 'group1',
            usageYearMonth: DateTime(2024, 8),
            usedPoint: 120,
            memo: '家族旅行',
          ),
        ],
        availableHeight: 100.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2024-08  120pt'), findsOneWidget);
      expect(find.text('家族旅行'), findsOneWidget);
    });

    testWidgets('メモは折り返さず、表示しきれない場合は省略表示を設定する', (WidgetTester tester) async {
      // Arrange
      const memo = 'とても長いメモですとても長いメモですとても長いメモです';
      final widget = DvcCell(
        usages: [
          DvcPointUsageDto(
            id: '1',
            groupId: 'group1',
            usageYearMonth: DateTime(2024, 8),
            usedPoint: 120,
            memo: memo,
          ),
        ],
        availableHeight: 100.0,
        availableWidth: 80.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      final memoText = tester.widget<Text>(find.text(memo));
      expect(memoText.maxLines, 1);
      expect(memoText.softWrap, isFalse);
      expect(memoText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('利用可能な高さが小さい場合、省略件数を表示する', (WidgetTester tester) async {
      // Arrange
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

      final widget = DvcCell(
        usages: usages,
        availableHeight: 64.0,
        availableWidth: 200.0,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('2024-01  100pt'), findsOneWidget);
      expect(find.text('メモ0'), findsOneWidget);
      expect(find.textContaining('…他9件'), findsOneWidget);
    });
  });
}
