import 'package:equatable/equatable.dart';

enum CalendarWeekStart {
  sunday,
  monday;

  int get weekday => this == monday ? DateTime.monday : DateTime.sunday;
  List<String> get dayNames => this == monday
      ? const ['月', '火', '水', '木', '金', '土', '日']
      : const ['日', '月', '火', '水', '木', '金', '土'];
}

class CalendarDisplaySettings extends Equatable {
  const CalendarDisplaySettings({
    this.weekStart = CalendarWeekStart.sunday,
    this.showRokuyo = false,
  });

  final CalendarWeekStart weekStart;
  final bool showRokuyo;

  CalendarDisplaySettings copyWith({
    CalendarWeekStart? weekStart,
    bool? showRokuyo,
  }) => CalendarDisplaySettings(
    weekStart: weekStart ?? this.weekStart,
    showRokuyo: showRokuyo ?? this.showRokuyo,
  );

  @override
  List<Object?> get props => [weekStart, showRokuyo];
}
