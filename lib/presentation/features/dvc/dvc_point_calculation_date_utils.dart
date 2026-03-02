DateTime dvcMonthStart(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month);

DateTime dvcAddMonths(DateTime dateTime, int months) {
  return DateTime(dateTime.year, dateTime.month + months);
}

String dvcMonthKey(DateTime dateTime) => '${dateTime.year}-${dateTime.month}';

String dvcFormatYearMonth(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  return '${dateTime.year}-$month';
}
