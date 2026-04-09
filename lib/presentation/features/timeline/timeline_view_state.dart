class TimelineViewState {
  TimelineViewState({
    required this.baseYear,
    required this.startYearOffset,
    required this.endYearOffset,
    required Map<String, double> rowHeightsByRowId,
    List<String>? rowIds,
  }) : rowHeightsByRowId = Map.unmodifiable(rowHeightsByRowId),
       rowIds = List.unmodifiable(rowIds ?? rowHeightsByRowId.keys);

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
      rowIds: rowIds,
    );
  }

  final int baseYear;
  final int startYearOffset;
  final int endYearOffset;
  final Map<String, double> rowHeightsByRowId;
  final List<String> rowIds;

  List<double> get rowHeights {
    return [for (final rowId in rowIds) rowHeightByRowId(rowId)];
  }

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
    List<String>? rowIds,
  }) {
    return TimelineViewState(
      baseYear: baseYear ?? this.baseYear,
      startYearOffset: startYearOffset ?? this.startYearOffset,
      endYearOffset: endYearOffset ?? this.endYearOffset,
      rowHeightsByRowId:
          rowHeightsByRowId ?? Map<String, double>.from(this.rowHeightsByRowId),
      rowIds: rowIds ?? List<String>.from(this.rowIds),
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
    final hasSameRows =
        this.rowIds.length == rowIds.length &&
        this.rowIds.indexed.every((entry) => entry.$2 == rowIds[entry.$1]);
    final hasAllHeights = rowIds.every(rowHeightsByRowId.containsKey);

    if (hasSameRows && hasAllHeights) {
      return this;
    }

    return copyWith(
      rowHeightsByRowId: {
        for (final rowId in rowIds)
          rowId: rowHeightsByRowId[rowId] ?? dataRowHeight,
      },
      rowIds: rowIds,
    );
  }

  TimelineViewState resizeRow({
    required String rowId,
    required double delta,
    required double minHeight,
    required double maxHeight,
  }) {
    final updatedHeights = Map<String, double>.from(rowHeightsByRowId);
    updatedHeights[rowId] = (rowHeightByRowId(rowId) + delta).clamp(
      minHeight,
      maxHeight,
    );
    return copyWith(rowHeightsByRowId: updatedHeights);
  }

  double rowHeightByRowId(String rowId) {
    final height = rowHeightsByRowId[rowId];
    if (height == null) {
      throw ArgumentError.value(rowId, 'rowId', '行の高さが未登録です');
    }
    return height;
  }

  int yearFromColumnIndex(int columnIndex) {
    final yearIndex = columnIndex - 1;
    return baseYear + startYearOffset + yearIndex;
  }
}
