class CalendarEventDraftDto {
  const CalendarEventDraftDto({
    this.title = '',
    this.memo = '',
    this.locationName = '',
    this.start,
    this.end,
    this.isAllDay = false,
  });

  final String title;
  final String memo;
  final String locationName;
  final DateTime? start;
  // 終日はUTCの年月日で、終了日は期間に含まない。
  final DateTime? end;
  final bool isAllDay;
}
