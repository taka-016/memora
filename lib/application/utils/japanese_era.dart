/// 日本の和暦計算を行うユーティリティクラス
class JapaneseEra {
  /// 和暦の元号と開始日の定義
  static final List<Map<String, dynamic>> _eras = [
    {'name': '令和', 'start': DateTime(2019, 5, 1)},
    {'name': '平成', 'start': DateTime(1989, 1, 8)},
    {'name': '昭和', 'start': DateTime(1926, 12, 25)},
    {'name': '大正', 'start': DateTime(1912, 7, 30)},
    {'name': '明治', 'start': DateTime(1868, 1, 25)},
  ];

  /// 指定された日付を和暦フォーマットで返す
  ///
  /// [date] フォーマットする日付
  /// 戻り値: "令和6年7月21日" のような形式の文字列
  static String formatJapaneseEra(DateTime date) {
    for (var era in _eras) {
      final start = era['start'] as DateTime;
      if (!date.isBefore(start)) {
        final year = date.year - start.year + 1;
        final eraYear = (year == 1) ? '元' : '$year';
        return '${era['name']}$eraYear年${date.month}月${date.day}日';
      }
    }

    // 明治以前の場合は西暦で表示
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 指定された西暦年を "2024年(令和6年)" 形式でフォーマットする
  ///
  /// [year] 西暦年
  /// 戻り値: "西暦年(和暦年)" の形式の文字列
  static String formatJapaneseEraYear(int year) {
    // 年の中間の日付（7月1日）で判定することで、その年の主要な和暦を使用
    final date = DateTime(year, 7, 1);

    for (var era in _eras) {
      final start = era['start'] as DateTime;
      if (!date.isBefore(start)) {
        final eraYear = year - start.year + 1;
        final eraYearString = (eraYear == 1) ? '元' : '$eraYear';
        return '$year年(${era['name']}$eraYearString年)';
      }
    }

    // 明治以前の場合は西暦のみ
    return '$year年';
  }
}
