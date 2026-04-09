import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/timeline_view_state.dart';

void main() {
  group('GroupTimelineViewState', () {
    test('初期状態では現在年を基準に前後5年を表示対象年として返す', () {
      final state = TimelineViewState.initial(
        baseYear: 2026,
        rowIds: const ['trip', 'group_event', 'dvc', 'member:member1'],
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
      final state = TimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeightsByRowId: const {'trip': 100, 'group_event': 120},
      );

      final updated = state.ensureRows(
        rowIds: const ['trip', 'group_event', 'dvc', 'member:member1'],
        dataRowHeight: 100,
      );

      expect(updated.rowHeightsByRowId, {
        'trip': 100,
        'group_event': 120,
        'dvc': 100,
        'member:member1': 100,
      });
    });

    test('行IDを指定した高さ変更は最小値と最大値の範囲に収める', () {
      final state = TimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeightsByRowId: const {'trip': 100},
      );

      final expanded = state.resizeRow(
        rowId: 'trip',
        delta: 50,
        minHeight: 80,
        maxHeight: 120,
      );
      final collapsed = state.resizeRow(
        rowId: 'trip',
        delta: -50,
        minHeight: 80,
        maxHeight: 120,
      );

      expect(expanded.rowHeightsByRowId['trip'], 120);
      expect(collapsed.rowHeightsByRowId['trip'], 80);
    });

    test('列インデックスから求める年はbaseYearを基準に固定される', () {
      final state = TimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeightsByRowId: const {'trip': 100},
      );

      expect(state.yearFromColumnIndex(1), 2021);
      expect(state.yearFromColumnIndex(6), 2026);
      expect(state.yearFromColumnIndex(11), 2031);
    });

    test('rowHeightsByRowIdは外部から直接変更できない', () {
      final sourceRowHeights = <String, double>{'trip': 100};
      final state = TimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeightsByRowId: sourceRowHeights,
      );

      sourceRowHeights['group_event'] = 120;

      expect(state.rowHeightsByRowId, {'trip': 100});
      expect(
        () => state.rowHeightsByRowId['group_event'] = 120,
        throwsUnsupportedError,
      );
    });

    test('未保持の行IDはデフォルト高さを返す', () {
      final state = TimelineViewState(
        baseYear: 2026,
        startYearOffset: -5,
        endYearOffset: 5,
        rowHeightsByRowId: const {'trip': 120},
      );

      expect(state.rowHeightFor('trip', defaultHeight: 100), 120);
      expect(state.rowHeightFor('group_event', defaultHeight: 100), 100);
    });
  });
}
