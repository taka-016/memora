import 'dart:async';

import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/notifiers/timeline/timeline_group_events_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_group_events_notifier.g.dart';

@riverpod
class TimelineGroupEventsNotifier extends _$TimelineGroupEventsNotifier {
  int _loadGeneration = 0;
  Map<int, GroupEventDto>? _lastLoadedEvents;

  @override
  TimelineGroupEventsState build(String groupId) {
    ref.listen(getGroupEventsUsecaseProvider, (_, _) => unawaited(reload()));
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
      final loaded = {for (final event in events) event.year: event};
      final previous = _lastLoadedEvents;
      final displayed = state.eventsByYear;
      final next = {...loaded};
      if (previous != null && displayed != null) {
        // 同じ取得結果では、セルに反映済みの編集結果を戻さない。
        for (final year in {...previous.keys, ...displayed.keys}) {
          if (previous[year] != loaded[year]) continue;
          final event = displayed[year];
          if (event == null) {
            next.remove(year);
          } else {
            next[year] = event;
          }
        }
      }
      _lastLoadedEvents = loaded;
      state = TimelineGroupEventsState(eventsByYear: next);
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
