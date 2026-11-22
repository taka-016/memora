import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/models/calendar_event_slice.dart';
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

  Future<({List<CalendarEventSlice> slices, List<CalendarLabelDto> labels})>
  load(
    String ownerId,
    String groupId,
    CalendarEventPeriod period, {
    required bool force,
  }) async {
    void checkOwner() {
      if (currentOwnerId() != ownerId) {
        throw StateError('カレンダーの表示対象のアカウントが変わりました');
      }
    }

    checkOwner();
    final cached = force
        ? null
        : await cache.loadEvents(ownerId, groupId, period);
    final slices = [...?cached?.slices];
    for (final missing in cached?.missing ?? [period]) {
      checkOwner();
      final observedAt = DateTime.now().microsecondsSinceEpoch;
      final events = await fetchEvents(groupId, period: missing);
      checkOwner();
      await cache.saveEvents(
        ownerId,
        groupId,
        missing,
        events,
        observedAt: observedAt,
      );
      slices.add(CalendarEventSlice(missing, events));
    }
    var labels = force ? null : await cache.loadLabels(ownerId, groupId);
    if (labels == null) {
      checkOwner();
      final observedAt = DateTime.now().microsecondsSinceEpoch;
      labels = await fetchLabels(groupId);
      checkOwner();
      await cache.saveLabels(ownerId, groupId, labels, observedAt: observedAt);
    }
    checkOwner();
    return (slices: slices, labels: labels);
  }
}
