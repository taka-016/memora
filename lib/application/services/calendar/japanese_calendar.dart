import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:qreki_dart/qreki_dart.dart';

abstract final class JapaneseCalendar {
  static String? holidayName(DateTime date) =>
      holiday_jp.getHoliday(date)?.name;

  static String rokuyo(DateTime date) =>
      Kyureki.fromYMD(date.year, date.month, date.day).rokuyouValue;
}
