class TimelineLayoutConfig {
  const TimelineLayoutConfig({
    required this.initialYearRange,
    required this.yearRangeIncrement,
    required this.dataRowHeight,
    required this.headerRowHeight,
    required this.borderWidth,
    required this.fixedColumnWidth,
    required this.buttonColumnWidth,
    required this.yearColumnWidth,
    required this.resizeBottomMargin,
    required this.rowMinHeight,
    required this.rowMaxHeight,
  });

  static const TimelineLayoutConfig defaults = TimelineLayoutConfig(
    initialYearRange: 5,
    yearRangeIncrement: 5,
    dataRowHeight: 100,
    headerRowHeight: 56,
    borderWidth: 1,
    fixedColumnWidth: 100,
    buttonColumnWidth: 100,
    yearColumnWidth: 120,
    resizeBottomMargin: 100,
    rowMinHeight: 100,
    rowMaxHeight: 500,
  );

  final int initialYearRange;
  final int yearRangeIncrement;
  final double dataRowHeight;
  final double headerRowHeight;
  final double borderWidth;
  final double fixedColumnWidth;
  final double buttonColumnWidth;
  final double yearColumnWidth;
  final double resizeBottomMargin;
  final double rowMinHeight;
  final double rowMaxHeight;
}
