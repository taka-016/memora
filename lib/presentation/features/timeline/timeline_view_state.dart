class TimelineViewState {
  TimelineViewState({
    required this.baseYear,
    required this.startYearOffset,
    required this.endYearOffset,
    this.refreshKey = 0,
    required List<double> rowHeights,
  }) : rowHeights = List.unmodifiable(rowHeights);

  factory TimelineViewState.initial({
    required int baseYear,
    required int totalDataRows,
    required int initialYearRange,
    required double dataRowHeight,
    List<double>? initialRowHeights,
  }) {
    return TimelineViewState(
      baseYear: baseYear,
      startYearOffset: -initialYearRange,
      endYearOffset: initialYearRange,
      refreshKey: 0,
      rowHeights:
          initialRowHeights ?? List.filled(totalDataRows, dataRowHeight),
    );
  }

  final int baseYear;
  final int startYearOffset;
  final int endYearOffset;
  final int refreshKey;
  final List<double> rowHeights;

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
    int? refreshKey,
    List<double>? rowHeights,
  }) {
    return TimelineViewState(
      baseYear: baseYear ?? this.baseYear,
      startYearOffset: startYearOffset ?? this.startYearOffset,
      endYearOffset: endYearOffset ?? this.endYearOffset,
      refreshKey: refreshKey ?? this.refreshKey,
      rowHeights: rowHeights ?? List<double>.from(this.rowHeights),
    );
  }

  TimelineViewState expandPast(int yearRangeIncrement) {
    return copyWith(startYearOffset: startYearOffset - yearRangeIncrement);
  }

  TimelineViewState expandFuture(int yearRangeIncrement) {
    return copyWith(endYearOffset: endYearOffset + yearRangeIncrement);
  }

  TimelineViewState refreshRows() {
    return copyWith(refreshKey: refreshKey + 1);
  }

  TimelineViewState ensureRowCount({
    required int totalDataRows,
    required double dataRowHeight,
    List<double>? initialRowHeights,
  }) {
    if (rowHeights.length == totalDataRows) {
      return this;
    }

    return copyWith(
      rowHeights: List<double>.generate(
        totalDataRows,
        (index) => index < rowHeights.length
            ? rowHeights[index]
            : initialRowHeights != null && index < initialRowHeights.length
            ? initialRowHeights[index]
            : dataRowHeight,
      ),
    );
  }

  TimelineViewState resizeRow({
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
