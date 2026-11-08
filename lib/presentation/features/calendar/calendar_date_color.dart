import 'package:flutter/material.dart';
import 'package:memora/application/services/calendar/japanese_calendar.dart';

Color? calendarDateColor(DateTime date, Brightness brightness) {
  return calendarWeekdayColor(
    date.weekday,
    brightness,
    isHoliday: JapaneseCalendar.holidayName(date) != null,
  );
}

Color? calendarWeekdayColor(
  int weekday,
  Brightness brightness, {
  bool isHoliday = false,
}) {
  if (weekday == DateTime.sunday || isHoliday) {
    return brightness == Brightness.dark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFD32F2F);
  }
  if (weekday == DateTime.saturday) {
    return brightness == Brightness.dark
        ? const Color(0xFF82B1FF)
        : const Color(0xFF1976D2);
  }
  return null;
}
