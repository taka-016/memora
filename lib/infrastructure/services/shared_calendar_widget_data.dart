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
    void Function(String, List<DateTime>)? onCancellationStarts,
  })
  fetchEvents;
  final Future<List<CalendarLabelDto>> Function(String groupId) fetchLabels;

  Future<CalendarWidgetGroupData> load(
    String ownerId,
    String groupId,
    List<CalendarEventPeriod> periods, {
    required bool force,
    bool forceLabels = false,
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
    Future<void> fetchMonths(List<CalendarEventPeriod> requested) async {
      requested.sort((a, b) => a.from.compareTo(b.from));
      for (var first = 0; first < requested.length;) {
        var last = first;
        while (last + 1 < requested.length &&
            requested[last].to == requested[last + 1].from) {
          last++;
        }
        final period = CalendarEventPeriod(
          from: requested[first].from,
          to: requested[last].to,
        );
        for (var attempt = 0; ; attempt++) {
          checkOwner();
          final observedAt = DateTime.now().microsecondsSinceEpoch;
          final cancellationStartsBySeries = <String, List<DateTime>>{};
          final events = await fetchEvents(
            groupId,
            period: period,
            onCancellationStarts: (id, starts) {
              cancellationStartsBySeries[id] = starts;
            },
          );
          checkOwner();
          if (await cache.saveEvents(
            ownerId,
            groupId,
            period,
            events,
            observedAt: observedAt,
            cancellationStartsBySeries: cancellationStartsBySeries,
          )) {
            for (final month in requested.getRange(first, last + 1)) {
              fetchedEvents[month] = events;
              observedTimes[month] = observedAt;
            }
            break;
          }
          if (attempt >= 1) {
            throw StateError('予定の取得中に変更が続いたため再取得できませんでした');
          }
        }
        first = last + 1;
      }
    }

    await fetchMonths([
      for (final period in periods)
        if (force || !snapshot.eventsByPeriod.containsKey(period)) period,
    ]);
    if (fetchedEvents.isNotEmpty) {
      snapshot = await cache.loadGroup(ownerId, groupId, periods);
      // 新たに取得した親予定によって、別の月にも取消情報が必要になる。
      await fetchMonths([
        for (final period in periods)
          if (!snapshot.eventsByPeriod.containsKey(period) &&
              (!fetchedEvents.containsKey(period) ||
                  (snapshot.observedAt[period] ?? 0) >= observedTimes[period]!))
            period,
      ]);
    }
    final cachedLabels = force || forceLabels ? null : snapshot.labels;
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
      snapshot = await cache.loadGroup(ownerId, groupId, periods);
    }
    checkOwner();
    final eventsByPeriod = <CalendarEventPeriod, List<CalendarEventDto>>{};
    final observedAt = <CalendarEventPeriod, int>{};
    for (final period in periods) {
      final cachedAt = snapshot.observedAt[period] ?? 0;
      final fetchedAt = observedTimes[period] ?? 0;
      final cached = snapshot.eventsByPeriod[period];
      final fetched = fetchedEvents[period];
      if (fetched != null && fetchedAt > cachedAt) {
        eventsByPeriod[period] = fetched;
        observedAt[period] = fetchedAt;
      } else if (cached != null) {
        eventsByPeriod[period] = cached;
        observedAt[period] = cachedAt;
      } else {
        throw StateError('表示する月の予定を取得できませんでした');
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
