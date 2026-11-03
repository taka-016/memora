class ExternalCalendarDto {
  const ExternalCalendarDto({required this.id, required this.name});
  final String id;
  final String name;
}

class ExternalCalendarAccount {
  const ExternalCalendarAccount({required this.id, required this.email});
  final String id;
  final String email;
}

class ExternalCalendarConnection {
  ExternalCalendarConnection({
    required this.account,
    Set<String> calendarIds = const {},
  }) : calendarIds = Set.unmodifiable(calendarIds);
  final ExternalCalendarAccount account;
  final Set<String> calendarIds;
}

class ExternalCalendarEventDto {
  const ExternalCalendarEventDto({
    required this.id,
    required this.calendarId,
    required this.calendarName,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
    this.memo = '',
    this.locationName = '',
    this.isRecurring = false,
    this.recurrence = const [],
    this.timeZone,
  });
  final String id;
  final String calendarId;
  final String calendarName;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String memo;
  final String locationName;
  final bool isRecurring;
  final List<String> recurrence;
  final String? timeZone;
}
