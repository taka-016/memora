import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class CalendarRecurrenceSettings {
  const CalendarRecurrenceSettings({
    this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay,
    this.ordinal,
    this.count,
    this.until,
  });
  final String? frequency;
  final int interval;
  final List<int> weekdays;
  final int? monthDay;
  final int? ordinal;
  final int? count;
  final DateTime? until;
  static const dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  static const dayNames = ['月', '火', '水', '木', '金', '土', '日'];

  factory CalendarRecurrenceSettings.preset(String name, DateTime start) =>
      switch (name) {
        'daily' => const CalendarRecurrenceSettings(frequency: 'DAILY'),
        'weekly' => CalendarRecurrenceSettings(
          frequency: 'WEEKLY',
          weekdays: [start.weekday],
        ),
        'monthly' => CalendarRecurrenceSettings(
          frequency: 'MONTHLY',
          monthDay: start.day,
        ),
        'yearly' => const CalendarRecurrenceSettings(frequency: 'YEARLY'),
        'weekdays' => const CalendarRecurrenceSettings(
          frequency: 'WEEKLY',
          weekdays: [1, 2, 3, 4, 5],
        ),
        _ => const CalendarRecurrenceSettings(),
      };
  factory CalendarRecurrenceSettings.fromRule(
    String? text,
    DateTime start, {
    String? zone,
    CalendarRecurrenceExpander? expander,
  }) {
    if (text == null) return const CalendarRecurrenceSettings();
    final value = CalendarRecurrenceRule.parse(text);
    final until = value.until == null
        ? null
        : zone == null
        ? value.until
        : expander!.localTime(value.until!, zone);
    return CalendarRecurrenceSettings(
      frequency: value.frequency,
      interval: value.interval,
      weekdays: value.weekdays,
      monthDay: value.monthDay,
      ordinal: value.ordinal,
      count: value.count,
      until: until,
    );
  }
  String get summary {
    if (frequency == null) return '繰り返さない';
    final unit = switch (frequency) {
      'DAILY' => '日',
      'WEEKLY' => '週',
      'MONTHLY' => '月',
      _ => '年',
    };
    var result = interval == 1
        ? '毎$unit'
        : '$interval${switch (frequency) {
            'DAILY' => '日',
            'WEEKLY' => '週間',
            'MONTHLY' => 'か月',
            _ => '年',
          }}ごと';
    if (weekdays.isNotEmpty) {
      final days = (weekdays.toList()..sort())
          .map((v) => dayNames[v - 1])
          .join('・');
      result += frequency == 'MONTHLY'
          ? 'の${ordinal == -1 ? '最終' : '第$ordinal'}$days曜日'
          : 'の$days曜日';
    } else if (monthDay != null) {
      result += 'の$monthDay日';
    }
    if (count != null) result += '、$count回';
    if (until != null)
      result += '、${until!.year}/${until!.month}/${until!.day}まで';
    return result;
  }

  String? toRule({
    required DateTime start,
    required bool allDay,
    required String zone,
    required CalendarRecurrenceExpander expander,
  }) {
    if (frequency == null) return null;
    try {
      final days = weekdays.toList()..sort();
      final wall = DateTime.utc(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
        start.second,
        start.millisecond,
        start.microsecond,
      );
      final instant = allDay ? wall : expander.resolveTime(wall, zone);
      final text = [
        'FREQ=$frequency',
        if (interval != 1) 'INTERVAL=$interval',
        if (days.isNotEmpty)
          'BYDAY=${days.map((day) => '${ordinal ?? ''}${dayCodes[day - 1]}').join(',')}',
        if (monthDay != null) 'BYMONTHDAY=$monthDay',
        if (count != null) 'COUNT=$count',
        if (until != null) 'UNTIL=${_untilText(allDay, zone, expander)}',
      ].join(';');
      final parsed = CalendarRecurrenceRule.parse(text);
      parsed.validateStart(instant, allDay, text);
      if (!parsed.matches(DateTime.utc(wall.year, wall.month, wall.day), wall))
        throw ValidationException('開始日は繰り返し条件に一致する必要があります');
      return text;
    } on ValidationException catch (e) {
      throw ApplicationValidationException(e.message);
    }
  }

  String _untilText(
    bool allDay,
    String zone,
    CalendarRecurrenceExpander expander,
  ) {
    final value = allDay
        ? until!
        : expander.resolveTime(
            DateTime.utc(until!.year, until!.month, until!.day, 23, 59, 59),
            zone,
          );
    final date =
        '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
    if (allDay) return date;
    return '${date}T${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}Z';
  }
}
