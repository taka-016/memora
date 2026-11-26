import 'package:memora/application/dtos/group/group_event_dto.dart';

class TimelineGroupEventsState {
  TimelineGroupEventsState({
    Map<int, GroupEventDto>? eventsByYear,
    this.isLoading = false,
    this.error,
  }) : eventsByYear = eventsByYear == null
           ? null
           : Map.unmodifiable(eventsByYear);

  final Map<int, GroupEventDto>? eventsByYear;
  final bool isLoading;
  final Object? error;
}
