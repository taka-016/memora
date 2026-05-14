import 'package:flutter/material.dart';

class AppDateTime {
  const AppDateTime._();

  static DateTime utc(DateTime dateTime) => dateTime.toUtc();

  static DateTime dateOnlyUtc(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }

  static DateTime monthStartUtc(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month);
  }

  static DateTime localDateFromUtc(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static TimeOfDay localTimeFromUtc(DateTime dateTime) {
    final local = dateTime.toLocal();
    return TimeOfDay(hour: local.hour, minute: local.minute);
  }

  static DateTime localDateAndTimeToUtc(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
  }
}
