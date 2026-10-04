abstract class CalendarTimeZone {
  DateTime local(DateTime instant, String zone);
  DateTime? resolve(DateTime wallTime, String zone);
}
