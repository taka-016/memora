import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';

class ExternalCalendarState {
  ExternalCalendarState({
    required this.month,
    this.connection,
    List<ExternalCalendarDto> calendars = const [],
    List<ExternalCalendarEventDto> events = const [],
    this.isLoading = false,
    this.isBusy = false,
    this.isStale = false,
    this.error = '',
    this.failure,
  }) : calendars = List.unmodifiable(calendars), events = List.unmodifiable(events);
  final DateTime month;
  final ExternalCalendarConnection? connection;
  final List<ExternalCalendarDto> calendars;
  final List<ExternalCalendarEventDto> events;
  final bool isLoading;
  final bool isBusy;
  final bool isStale;
  final String error;
  final ExternalCalendarFailure? failure;
  bool get needsAuthentication => failure == ExternalCalendarFailure.authentication || failure == ExternalCalendarFailure.permission;

  ExternalCalendarState copyWith({DateTime? month, ExternalCalendarConnection? connection, bool clearConnection = false, List<ExternalCalendarDto>? calendars, List<ExternalCalendarEventDto>? events, bool? isLoading, bool? isBusy, bool? isStale, String? error, ExternalCalendarFailure? failure}) => ExternalCalendarState(
    month: month ?? this.month, connection: clearConnection ? null : connection ?? this.connection,
    calendars: calendars ?? this.calendars, events: events ?? this.events,
    isLoading: isLoading ?? this.isLoading, isBusy: isBusy ?? this.isBusy,
    isStale: isStale ?? this.isStale, error: error ?? this.error, failure: failure,
  );
}
