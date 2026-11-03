import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';

class ExternalCalendarState {
  ExternalCalendarState({
    required this.month,
    List<ExternalCalendarConnection> connections = const [],
    Map<String, List<ExternalCalendarDto>> calendarsByAccount = const {},
    Map<String, List<ExternalCalendarEventDto>> eventsByAccount = const {},
    Map<String, ExternalCalendarException> failures = const {},
    this.isLoading = false,
    this.isBusy = false,
    this.error = '',
    this.failure,
  }) : connections = List.unmodifiable(connections),
       calendarsByAccount = Map.unmodifiable({
         for (final entry in calendarsByAccount.entries)
           entry.key: List<ExternalCalendarDto>.unmodifiable(entry.value),
       }),
       eventsByAccount = Map.unmodifiable({
         for (final entry in eventsByAccount.entries)
           entry.key: List<ExternalCalendarEventDto>.unmodifiable(entry.value),
       }),
       failures = Map.unmodifiable(failures);

  final DateTime month;
  final List<ExternalCalendarConnection> connections;
  final Map<String, List<ExternalCalendarDto>> calendarsByAccount;
  final Map<String, List<ExternalCalendarEventDto>> eventsByAccount;
  final Map<String, ExternalCalendarException> failures;
  final bool isLoading;
  final bool isBusy;
  final String error;
  final ExternalCalendarFailure? failure;
  List<ExternalCalendarEventDto> get events => [
    for (final events in eventsByAccount.values) ...events,
  ];
  bool needsAuthenticationFor(String accountId) =>
      failures[accountId]?.kind == ExternalCalendarFailure.authentication ||
      failures[accountId]?.kind == ExternalCalendarFailure.permission;

  ExternalCalendarState copyWith({
    DateTime? month,
    List<ExternalCalendarConnection>? connections,
    Map<String, List<ExternalCalendarDto>>? calendarsByAccount,
    Map<String, List<ExternalCalendarEventDto>>? eventsByAccount,
    Map<String, ExternalCalendarException>? failures,
    bool? isLoading,
    bool? isBusy,
    String? error,
    ExternalCalendarFailure? failure,
  }) => ExternalCalendarState(
    month: month ?? this.month,
    connections: connections ?? this.connections,
    calendarsByAccount: calendarsByAccount ?? this.calendarsByAccount,
    eventsByAccount: eventsByAccount ?? this.eventsByAccount,
    failures: failures ?? this.failures,
    isLoading: isLoading ?? this.isLoading,
    isBusy: isBusy ?? this.isBusy,
    error: error ?? this.error,
    failure: failure,
  );
}
