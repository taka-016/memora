import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_widget_group_data.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';

class SharedCalendarWidgetData {
  const SharedCalendarWidgetData({
    required this.cache,
    required this.currentOwnerId,
    required this.fetchEvents,
    required this.fetchLabels,
  });

  final SharedCalendarCache cache;
  final String? Function() currentOwnerId;
  final Future<List<CalendarEventDto>> Function(
    String groupId, {
    CalendarEventPeriod? period,
  })
  fetchEvents;
  final Future<List<CalendarLabelDto>> Function(String groupId) fetchLabels;

  Future<CalendarWidgetGroupData> load(
    String ownerId,
    String groupId,
    List<CalendarEventPeriod> periods, {
    required bool force,
  }) async {
    void checkOwner() {
      if (currentOwnerId() != ownerId) {
        throw StateError('カレンダーの表示対象のアカウントが変わりました');
      }
    }

    checkOwner();
    var snapshot = await cache.loadGroup(ownerId, groupId, periods);
    final fetchedEvents = <CalendarEventPeriod, List<CalendarEventDto>>{};
    final observedTimes = <CalendarEventPeriod, int>{};
    for (final period in periods) {
      if (!force && snapshot.eventsByPeriod.containsKey(period)) continue;
      for (var attempt = 0; ; attempt++) {
        checkOwner();
        final observedAt = DateTime.now().microsecondsSinceEpoch;
        final events = await fetchEvents(groupId, period: period);
        checkOwner();
        if (await cache.saveEvents(
          ownerId,
          groupId,
          period,
          events,
          observedAt: observedAt,
        )) {
          fetchedEvents[period] = events;
          observedTimes[period] = observedAt;
          break;
        }
        if (attempt >= 1) {
          throw StateError('予定の取得中に変更が続いたため再取得できませんでした');
        }
      }
    }
    final cachedLabels = force ? null : snapshot.labels;
    List<CalendarLabelDto>? fetchedLabels;
    var labelsObservedAt = 0;
    if (cachedLabels == null) {
      checkOwner();
      labelsObservedAt = DateTime.now().microsecondsSinceEpoch;
      fetchedLabels = await fetchLabels(groupId);
      checkOwner();
      await cache.saveLabels(
        ownerId,
        groupId,
        fetchedLabels,
        observedAt: labelsObservedAt,
      );
    }
    if (fetchedEvents.isNotEmpty || fetchedLabels != null) {
      final latest = await cache.loadGroup(ownerId, groupId, periods);
      if (latest.labels != null &&
          latest.eventsByPeriod.length == periods.length) {
        snapshot = latest;
      }
    }
    checkOwner();
    final eventsByPeriod = <CalendarEventPeriod, List<CalendarEventDto>>{};
    final observedAt = <CalendarEventPeriod, int>{};
    for (final period in periods) {
      final cachedAt = snapshot.observedAt[period] ?? 0;
      final fetchedAt = observedTimes[period] ?? 0;
      if (fetchedAt > cachedAt) {
        eventsByPeriod[period] = fetchedEvents[period]!;
        observedAt[period] = fetchedAt;
      } else {
        eventsByPeriod[period] = snapshot.eventsByPeriod[period] ?? const [];
        observedAt[period] = cachedAt;
      }
    }
    return CalendarWidgetGroupData(
      eventsByPeriod: eventsByPeriod,
      labels: labelsObservedAt > snapshot.labelsObservedAt
          ? fetchedLabels
          : snapshot.labels,
      observedAt: observedAt,
      sourceFiles: snapshot.sourceFiles,
      synchronizedPeriods: fetchedEvents.keys.toSet(),
    );
  }
}
