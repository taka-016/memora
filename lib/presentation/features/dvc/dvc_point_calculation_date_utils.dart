import 'package:memora/core/time/app_date_time.dart';

DateTime dvcMonthStart(DateTime dateTime) =>
    AppDateTime.monthStartUtc(dateTime);

DateTime dvcAddMonths(DateTime dateTime, int months) {
  return DateTime.utc(dateTime.year, dateTime.month + months);
}

String dvcMonthKey(DateTime dateTime) => '${dateTime.year}-${dateTime.month}';

String dvcFormatYearMonth(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  return '${dateTime.year}-$month';
}
