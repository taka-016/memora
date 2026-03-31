class GroupTimelineViewState {
  const GroupTimelineViewState({
    required this.startYearOffset,
    required this.endYearOffset,
    required this.rowHeights,
  });

  factory GroupTimelineViewState.initial({
    required int totalDataRows,
    required int initialYearRange,
    required double dataRowHeight,
  }) {
    return GroupTimelineViewState(
      startYearOffset: -initialYearRange,
      endYearOffset: initialYearRange,
      rowHeights: List.filled(totalDataRows, dataRowHeight),
    );
  }

  final int startYearOffset;
  final int endYearOffset;
  final List<double> rowHeights;

  List<int> get visibleYears {
    final currentYear = DateTime.now().year;
    return [
      for (int offset = startYearOffset; offset <= endYearOffset; offset++)
        currentYear + offset,
    ];
  }

  GroupTimelineViewState copyWith({
    int? startYearOffset,
    int? endYearOffset,
    List<double>? rowHeights,
  }) {
    return GroupTimelineViewState(
      startYearOffset: startYearOffset ?? this.startYearOffset,
      endYearOffset: endYearOffset ?? this.endYearOffset,
      rowHeights: rowHeights ?? this.rowHeights,
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
    final currentYear = DateTime.now().year;
    final yearIndex = columnIndex - 1;
    return currentYear + startYearOffset + yearIndex;
  }
}
