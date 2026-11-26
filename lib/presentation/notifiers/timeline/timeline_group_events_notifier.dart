import 'dart:async';

import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/notifiers/timeline/timeline_group_events_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_group_events_notifier.g.dart';

@riverpod
class TimelineGroupEvents extends _$TimelineGroupEvents {
  int _loadGeneration = 0;

  @override
  TimelineGroupEventsState build(String groupId) {
    ref.listen(timelineRowsRefreshProvider, (_, _) => unawaited(reload()));
    unawaited(Future.microtask(reload));
    return TimelineGroupEventsState(isLoading: true);
  }

  Future<void> reload() async {
    if (!ref.mounted) return;
    final generation = ++_loadGeneration;
    state = TimelineGroupEventsState(
      eventsByYear: state.eventsByYear,
      isLoading: true,
    );
    try {
      final events = await ref
          .read(getGroupEventsUsecaseProvider)
          .execute(groupId);
      if (!ref.mounted || generation != _loadGeneration) return;
      state = TimelineGroupEventsState(
        eventsByYear: {for (final event in events) event.year: event},
      );
    } catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = TimelineGroupEventsState(
        eventsByYear: state.eventsByYear,
        error: error,
      );
    }
  }

  Future<void> save({
    required int year,
    required String memo,
    required GroupEventDto? eventAtOpen,
  }) async {
    final savedEvent = await ref
        .read(editGroupEventUsecaseProvider)
        .execute(
          groupId: groupId,
          year: year,
          memo: memo,
          eventAtOpen: eventAtOpen,
        );
    if (!ref.mounted) return;
    final events = {...?state.eventsByYear};
    if (savedEvent == null) {
      events.remove(year);
    } else {
      events[year] = savedEvent;
    }
    state = TimelineGroupEventsState(eventsByYear: events);
    unawaited(reload());
  }
}
