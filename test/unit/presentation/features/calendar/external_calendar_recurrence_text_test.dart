import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/external_calendar_recurrence_text.dart';

void main() {
  test('繰り返しの頻度・曜日・終了回数を日本語で表示する', () {
    final text = externalCalendarRecurrenceText('RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR;COUNT=10');
    expect(text, contains('2週間ごと'));
    expect(text, contains('月・金'));
    expect(text, contains('10回'));
  });
  test('月の指定日と終了日・除外日・追加日を欠落させない', () {
    expect(externalCalendarRecurrenceText('RRULE:FREQ=MONTHLY;BYMONTHDAY=1,-1;UNTIL=20261231'), contains('2026/12/31'));
    expect(externalCalendarRecurrenceText('RRULE:FREQ=MONTHLY;BYDAY=-1FR;BYSETPOS=1'), contains('最終金'));
    expect(externalCalendarRecurrenceText('EXDATE;TZID=Asia/Tokyo:20261106T090000'), contains('2026/11/6 09:00:00'));
    expect(externalCalendarRecurrenceText('RDATE;VALUE=DATE:20261101,20261102'), contains('2026/11/1・2026/11/2'));
  });
}
