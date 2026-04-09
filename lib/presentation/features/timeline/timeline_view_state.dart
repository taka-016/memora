class TimelineViewState {
  TimelineViewState({
    required this.baseYear,
    required this.startYearOffset,
    required this.endYearOffset,
    required Map<String, double> rowHeightsByRowId,
  }) : rowHeightsByRowId = Map.unmodifiable(rowHeightsByRowId);

  factory TimelineViewState.initial({
    required int baseYear,
    required List<String> rowIds,
    required int initialYearRange,
    required double dataRowHeight,
  }) {
    return TimelineViewState(
      baseYear: baseYear,
      startYearOffset: -initialYearRange,
      endYearOffset: initialYearRange,
      rowHeightsByRowId: {for (final rowId in rowIds) rowId: dataRowHeight},
    );
  }

  final int baseYear;
  final int startYearOffset;
  final int endYearOffset;
  final Map<String, double> rowHeightsByRowId;

  List<int> get visibleYears {
    return [
      for (int offset = startYearOffset; offset <= endYearOffset; offset++)
        baseYear + offset,
    ];
  }

  TimelineViewState copyWith({
    int? baseYear,
    int? startYearOffset,
    int? endYearOffset,
    Map<String, double>? rowHeightsByRowId,
  }) {
    return TimelineViewState(
      baseYear: baseYear ?? this.baseYear,
      startYearOffset: startYearOffset ?? this.startYearOffset,
      endYearOffset: endYearOffset ?? this.endYearOffset,
      rowHeightsByRowId:
          rowHeightsByRowId ?? Map<String, double>.from(this.rowHeightsByRowId),
    );
  }

  TimelineViewState expandPast(int yearRangeIncrement) {
    return copyWith(startYearOffset: startYearOffset - yearRangeIncrement);
  }

  TimelineViewState expandFuture(int yearRangeIncrement) {
    return copyWith(endYearOffset: endYearOffset + yearRangeIncrement);
  }

  TimelineViewState ensureRows({
    required List<String> rowIds,
    required double dataRowHeight,
  }) {
    if (rowIds.every(rowHeightsByRowId.containsKey)) {
      return this;
    }

    final updatedHeights = Map<String, double>.from(rowHeightsByRowId);
    for (final rowId in rowIds) {
      updatedHeights.putIfAbsent(rowId, () => dataRowHeight);
    }

    return copyWith(rowHeightsByRowId: updatedHeights);
  }

  double rowHeightFor(String rowId, {required double defaultHeight}) {
    return rowHeightsByRowId[rowId] ?? defaultHeight;
  }

  TimelineViewState resizeRow({
    required String rowId,
    required double delta,
    required double minHeight,
    required double maxHeight,
  }) {
    final currentHeight = rowHeightsByRowId[rowId];
    if (currentHeight == null) {
      return this;
    }
    final updatedHeights = Map<String, double>.from(rowHeightsByRowId);
    updatedHeights[rowId] = (currentHeight + delta).clamp(minHeight, maxHeight);
    return copyWith(rowHeightsByRowId: updatedHeights);
  }

  int yearFromColumnIndex(int columnIndex) {
    final yearIndex = columnIndex - 1;
    return baseYear + startYearOffset + yearIndex;
  }
}
