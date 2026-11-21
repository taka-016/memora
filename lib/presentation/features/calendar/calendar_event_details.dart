import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

String calendarDateText(DateTime value) =>
    '${value.year}/${value.month}/${value.day}';
String calendarTimeText(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String calendarPeriodText(CalendarEventDto event) {
  if (event.isAllDay) {
    final lastDay = DateTime.utc(
      event.endDateTime.year,
      event.endDateTime.month,
      event.endDateTime.day - 1,
    );
    return '${calendarDateText(event.startDateTime)} 〜 ${calendarDateText(lastDay)}（終日）';
  }
  final start = event.startDateTime.toLocal();
  final end = event.endDateTime.toLocal();
  return '${calendarDateText(start)} ${calendarTimeText(start)} 〜 ${calendarDateText(end)} ${calendarTimeText(end)}';
}

Future<String?> openCalendarEventUrl(
  String url,
  Future<bool> Function(Uri) openUrl,
) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty) {
    return 'httpまたはhttpsのURLを入力してください';
  }
  try {
    if (await openUrl(uri)) return null;
  } catch (_) {
    return 'URLを開けませんでした';
  }
  return 'URLを開けませんでした';
}
