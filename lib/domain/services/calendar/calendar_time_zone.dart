abstract class CalendarTimeZone {
  DateTime local(DateTime instant, String zone);
  DateTime? resolve(DateTime wallTime, String zone);
  List<DateTime> skippedDates(DateTime wallStart, DateTime before, String zone);
}
