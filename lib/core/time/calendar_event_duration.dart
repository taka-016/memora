Duration calendarEventDuration(DateTime start, DateTime end, bool isAllDay) =>
    isAllDay
        ? DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day))
        : end.difference(start);
