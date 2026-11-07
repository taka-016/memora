import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/japanese_calendar.dart';

void main() {
  test('祝日・振替休日・国民の休日と祝日の特例を判定する', () {
    for (final (date, name) in [
      (DateTime(2026, 11, 3), '文化の日'),
      (DateTime(2026, 5, 6), 'こどもの日 振替休日'),
      (DateTime(2026, 9, 22), '休日'),
      (DateTime(2019, 5, 1), '休日（祝日扱い）'),
      (DateTime(2021, 7, 23), 'スポーツの日'),
    ]) {
      expect(JapaneseCalendar.holidayName(date), name);
    }
    expect(JapaneseCalendar.holidayName(DateTime(2026, 11, 2)), isNull);
    expect(JapaneseCalendar.holidayName(DateTime(2021, 10, 11)), isNull);
    expect(JapaneseCalendar.holidayName(DateTime(2026, 11, 3, 23)), '文化の日');
  });

  test('六曜を旧暦の月替わりと閏月を含めて暦日から取得する', () {
    for (final (date, name) in [
      (DateTime(2017, 10, 17), '大安'),
      (DateTime(2017, 10, 21), '仏滅'),
      (DateTime(2020, 6, 14), '友引'),
      (DateTime(2026, 11, 8), '先勝'),
      (DateTime.utc(2026, 11, 9, 23), '仏滅'),
    ]) {
      expect(JapaneseCalendar.rokuyo(date), name);
    }
  });
}
