import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/group_timeline_view_state.dart';

void main() {
  group('GroupTimelineViewState', () {
    test('初期状態では現在年を基準に前後5年を表示対象年として返す', () {
      final state = GroupTimelineViewState.initial(
        baseYear: 2026,
        totalDataRows: 4,
        initialYearRange: 5,
        dataRowHeight: 100,
      );

      expect(state.baseYear, 2026);
      expect(state.startYearOffset, -5);
      expect(state.endYearOffset, 5);
      expect(state.visibleYears, [
        for (int year = 2021; year <= 2031; year++) year,
      ]);
    });

    test('行数が増えたときは既存の高さを維持して不足分だけデフォルト値を補う', () {
      final state = GroupTimelineViewState(
        baseYear: 2026,
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
        baseYear: 2026,
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

    test('列インデックスから求める年はbaseYearを基準に固定される', () {
      final state = GroupTimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeights: const [100],
      );

      expect(state.yearFromColumnIndex(1), 2021);
      expect(state.yearFromColumnIndex(6), 2026);
      expect(state.yearFromColumnIndex(11), 2031);
    });

    test('rowHeightsは外部から直接変更できない', () {
      final sourceRowHeights = <double>[100, 120];
      final state = GroupTimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeights: sourceRowHeights,
      );

      sourceRowHeights.add(140);

      expect(state.rowHeights, [100, 120]);
      expect(() => state.rowHeights.add(140), throwsUnsupportedError);
    });
  });
}
