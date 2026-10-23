import 'dart:async';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_watch_query_service.dart';

class EventSource implements CalendarEventWatchQueryService {
  final streams = <StreamController<List<CalendarEventDto>>>[];
  final groups = <String>[];
  int cancelled = 0;
  @override
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(String groupId) {
    groups.add(groupId);
    final stream = StreamController<List<CalendarEventDto>>(
      onCancel: () {
        cancelled++;
      },
    );
    streams.add(stream);
    return stream.stream;
  }
}

class LabelSource implements CalendarLabelWatchQueryService {
  final streams = <StreamController<List<CalendarLabelDto>>>[];
  int cancelled = 0;
  @override
  Stream<List<CalendarLabelDto>> watchCalendarLabelsByGroupId(String groupId) {
    final stream = StreamController<List<CalendarLabelDto>>(
      onCancel: () {
        cancelled++;
      },
    );
    streams.add(stream);
    return stream.stream;
  }
}
