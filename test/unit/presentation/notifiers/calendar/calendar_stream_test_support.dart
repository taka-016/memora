import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/calendar/calendar_group_watch_query_service.dart';

import 'dart:async';

import 'package:memora/application/models/calendar_event_period.dart';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_watch_query_service.dart';

class EventSource implements CalendarEventWatchQueryService {
  final streams = <StreamController<List<CalendarEventDto>>>[];
  final groups = <String>[];
  final periods = <CalendarEventPeriod?>[];
  int cancelled = 0;
  @override
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) {
    periods.add(period);
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

class GroupSource implements CalendarGroupWatchQueryService {
  final stream = StreamController<GroupDto?>();
  @override
  Stream<GroupDto?> watchCalendarGroup(String groupId) => stream.stream;
}
