class JapaneseEraFormatter {
  static final List<Map<String, dynamic>> _eras = [
    {'name': '令和', 'start': DateTime(2019, 5, 1)},
    {'name': '平成', 'start': DateTime(1989, 1, 8)},
    {'name': '昭和', 'start': DateTime(1926, 12, 25)},
    {'name': '大正', 'start': DateTime(1912, 7, 30)},
    {'name': '明治', 'start': DateTime(1868, 1, 25)},
  ];

  static String formatJapaneseEraFormatter(DateTime date) {
    for (var era in _eras) {
      final start = era['start'] as DateTime;
      if (!date.isBefore(start)) {
        final year = date.year - start.year + 1;
        final eraYear = (year == 1) ? '元' : '$year';
        return '${era['name']}$eraYear年${date.month}月${date.day}日';
      }
    }

    return '${date.year}年${date.month}月${date.day}日';
  }

  static String formatJapaneseEraFormatterYear(int year) {
    final date = DateTime(year, 7, 1);

    for (var era in _eras) {
      final start = era['start'] as DateTime;
      if (!date.isBefore(start)) {
        final eraYear = year - start.year + 1;
        final eraYearString = (eraYear == 1) ? '元' : '$eraYear';
        return '${era['name']}$eraYearString年';
      }
    }

    return '$year年';
  }
}
