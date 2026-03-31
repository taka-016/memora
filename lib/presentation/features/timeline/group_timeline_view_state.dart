class GroupTimelineViewState {
  GroupTimelineViewState({
    required this.baseYear,
    required this.startYearOffset,
    required this.endYearOffset,
    required List<double> rowHeights,
  }) : rowHeights = List.unmodifiable(rowHeights);

  factory GroupTimelineViewState.initial({
    required int baseYear,
    required int totalDataRows,
    required int initialYearRange,
    required double dataRowHeight,
  }) {
    return GroupTimelineViewState(
      baseYear: baseYear,
      startYearOffset: -initialYearRange,
      endYearOffset: initialYearRange,
      rowHeights: List.filled(totalDataRows, dataRowHeight),
    );
  }

  final int baseYear;
  final int startYearOffset;
  final int endYearOffset;
  final List<double> rowHeights;

  List<int> get visibleYears {
    return [
      for (int offset = startYearOffset; offset <= endYearOffset; offset++)
        baseYear + offset,
    ];
  }

  GroupTimelineViewState copyWith({
    int? baseYear,
    int? startYearOffset,
    int? endYearOffset,
    List<double>? rowHeights,
  }) {
    return GroupTimelineViewState(
      baseYear: baseYear ?? this.baseYear,
      startYearOffset: startYearOffset ?? this.startYearOffset,
      endYearOffset: endYearOffset ?? this.endYearOffset,
      rowHeights: rowHeights ?? List<double>.from(this.rowHeights),
    );
  }

  GroupTimelineViewState expandPast(int yearRangeIncrement) {
    return copyWith(startYearOffset: startYearOffset - yearRangeIncrement);
  }

  GroupTimelineViewState expandFuture(int yearRangeIncrement) {
    return copyWith(endYearOffset: endYearOffset + yearRangeIncrement);
  }

  GroupTimelineViewState ensureRowCount({
    required int totalDataRows,
    required double dataRowHeight,
  }) {
    if (rowHeights.length == totalDataRows) {
      return this;
    }

    return copyWith(
      rowHeights: List<double>.generate(
        totalDataRows,
        (index) =>
            index < rowHeights.length ? rowHeights[index] : dataRowHeight,
      ),
    );
  }

  GroupTimelineViewState resizeRow({
    required int rowIndex,
    required double delta,
    required double minHeight,
    required double maxHeight,
  }) {
    final updatedHeights = List<double>.from(rowHeights);
    updatedHeights[rowIndex] = (updatedHeights[rowIndex] + delta).clamp(
      minHeight,
      maxHeight,
    );
    return copyWith(rowHeights: updatedHeights);
  }

  int yearFromColumnIndex(int columnIndex) {
    final yearIndex = columnIndex - 1;
    return baseYear + startYearOffset + yearIndex;
  }
}
