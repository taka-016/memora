import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/group_timeline_view_state.dart';

void main() {
  group('GroupTimelineViewState', () {
    test('初期状態では現在年を基準に前後5年を表示対象年として返す', () {
      final state = GroupTimelineViewState.initial(
        totalDataRows: 4,
        initialYearRange: 5,
        dataRowHeight: 100,
      );

      final currentYear = DateTime.now().year;

      expect(state.startYearOffset, -5);
      expect(state.endYearOffset, 5);
      expect(state.visibleYears, [
        for (int year = currentYear - 5; year <= currentYear + 5; year++) year,
      ]);
    });

    test('行数が増えたときは既存の高さを維持して不足分だけデフォルト値を補う', () {
      final state = GroupTimelineViewState(
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeights: const [100, 120],
      );

      final updated = state.ensureRowCount(
        totalDataRows: 4,
        dataRowHeight: 100,
      );

      expect(updated.rowHeights, [100, 120, 100, 100]);
    });

    test('行の高さ変更は最小値と最大値の範囲に収める', () {
      final state = GroupTimelineViewState(
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeights: const [100],
      );

      final expanded = state.resizeRow(
        rowIndex: 0,
        delta: 50,
        minHeight: 80,
        maxHeight: 120,
      );
      final collapsed = state.resizeRow(
        rowIndex: 0,
        delta: -50,
        minHeight: 80,
        maxHeight: 120,
      );

      expect(expanded.rowHeights, [120]);
      expect(collapsed.rowHeights, [80]);
    });
  });
}
