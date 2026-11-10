import 'package:equatable/equatable.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';

class CalendarEventPeriod extends Equatable {
  const CalendarEventPeriod({required this.from, required this.to});

  factory CalendarEventPeriod.forMonth(DateTime day) => CalendarEventPeriod(
    from: DateTime(day.year, day.month - 1, -6),
    to: DateTime(day.year, day.month + 2, 8),
  );

  factory CalendarEventPeriod.forNotifications(DateTime now) =>
      CalendarEventPeriod(
        from: DateTime(now.year, now.month, now.day),
        to: now.add(
          const Duration(
            days: 28 + 2,
            minutes: MAX_ALL_DAY_CALENDAR_NOTIFICATION_MINUTES,
          ),
        ),
      );

  final DateTime from;
  final DateTime to;

  // 終日はUTCの日付、時間指定は実時刻で保存されるため両方の境界を含める。
  DateTime get queryFrom {
    final date = DateTime.utc(from.year, from.month, from.day);
    return from.isBefore(date) ? from : date;
  }

  DateTime get queryTo {
    final date = DateTime.utc(to.year, to.month, to.day);
    return to.isAfter(date) ? to : date;
  }

  @override
  List<Object> get props => [from, to];
}
