import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/core/time/app_clock.dart';

class GetAndroidWidgetItineraryCacheUsecase {
  const GetAndroidWidgetItineraryCacheUsecase({
    required this._queryService,
    required this._clock,
  });

  final AndroidWidgetItineraryQueryService _queryService;
  final AppClock _clock;

  Future<AndroidWidgetItineraryCacheDto> execute({
    required String groupId,
    String? selectedItineraryDateId,
    Set<String> retainedItineraryDateIds = const {},
  }) async {
    final loaded = <DateTime, List<AndroidWidgetItineraryDateCacheDto>>{};
    Future<List<AndroidWidgetItineraryDateCacheDto>> loadDay(DateTime date) async {
      final day = _dateOnly(date);
      if (loaded.containsKey(day)) return loaded[day]!;
      final trips = await _queryService.getDay(groupId, day);
      final values = [for (final trip in trips) ..._toItineraryDateCaches(trip, trip.itineraryItems ?? const [])]..sort(_compareItineraryDateCaches);
      return loaded[day] = values;
    }
    final today = _dateOnly(_clock.now());
    final next = await _queryService.findDate(groupId, today, before: false);
    final recentDay = next ?? await _queryService.findDate(groupId, today, before: true);
    final recentValues = recentDay == null ? <AndroidWidgetItineraryDateCacheDto>[] : await loadDay(recentDay);
    final recent = next != null ? recentValues.firstOrNull : recentValues.lastOrNull;
    AndroidWidgetItineraryDateCacheDto? selected;
    if (selectedItineraryDateId != null && selectedItineraryDateId.length >= 10) {
      final date = DateTime.tryParse(selectedItineraryDateId.substring(selectedItineraryDateId.length - 10));
      if (date != null) selected = (await loadDay(date)).where((value) => value.id == selectedItineraryDateId).firstOrNull;
    }
    selected ??= recent;
    if (selected == null) {
      return AndroidWidgetItineraryCacheDto(version: 1, groupId: groupId, selectedItineraryDateId: null,
        lastUpdatedAt: _clock.now(), itineraryDates: const [], itineraryDateIds: const []);
    }
    final allDates = [...await loadDay(selected.date)]..sort(_compareItineraryDateCaches);
    var previousBoundary = selected.date;
    var nextBoundary = DateTime(selected.date.year, selected.date.month, selected.date.day + 1);
    int selectedIndex() => allDates.indexWhere((value) => value.id == selected!.id);
    while (selectedIndex() < 2) {
      final date = await _queryService.findDate(groupId, previousBoundary, before: true);
      if (date == null) break;
      previousBoundary = date;
      allDates.addAll(await loadDay(date));
      allDates.sort(_compareItineraryDateCaches);
    }
    while (allDates.length - selectedIndex() - 1 < 4) {
      final date = await _queryService.findDate(groupId, nextBoundary, before: false);
      if (date == null) break;
      nextBoundary = DateTime(date.year, date.month, date.day + 1);
      allDates.addAll(await loadDay(date));
      allDates.sort(_compareItineraryDateCaches);
    }
    final index = selectedIndex();
    final from = index > 1 ? index - 2 : 0;
    final to = index + 5 < allDates.length ? index + 5 : allDates.length;
    final references = allDates.sublist(from, to);
    final referenceIds = references.map((value) => value.id).toSet();
    final includedIds = {
      ...retainedItineraryDateIds.where(referenceIds.contains),
      ..._selectCacheRange(allDates, selected).map((value) => value.id),
    };
    return AndroidWidgetItineraryCacheDto(version: 1, groupId: groupId,
      selectedItineraryDateId: selected.id, lastUpdatedAt: _clock.now(),
      itineraryDates: references.where((value) => includedIds.contains(value.id)).toList(),
      itineraryDateIds: references.map((value) => value.id).toList(), recentItineraryDateId: recent?.id);
  }

  List<AndroidWidgetItineraryDateCacheDto> _selectCacheRange(
    List<AndroidWidgetItineraryDateCacheDto> itineraryDates,
    AndroidWidgetItineraryDateCacheDto? selectedItineraryDate,
  ) {
    if (selectedItineraryDate == null) return [];
    final selectedIndex = itineraryDates.indexWhere(
      (date) => date.id == selectedItineraryDate.id,
    );
    if (selectedIndex < 0) return [];
    final startIndex = selectedIndex > 0 ? selectedIndex - 1 : 0;
    final endExclusive = selectedIndex + 4 < itineraryDates.length
        ? selectedIndex + 4
        : itineraryDates.length;
    return itineraryDates.sublist(startIndex, endExclusive);
  }

  List<AndroidWidgetItineraryDateCacheDto> _toItineraryDateCaches(
    TripEntryDto trip,
    List<ItineraryItemDto> itineraryItems,
  ) {
    final sortedItems = [...itineraryItems]..sort(_compareItineraryItems);
    final itemsByDate = <DateTime, List<ItineraryItemDto>>{};
    for (final item in sortedItems) {
      final startDateTime = item.startDateTime;
      if (startDateTime == null) {
        continue;
      }
      final date = _dateOnly(startDateTime);
      itemsByDate.putIfAbsent(date, () => []).add(item);
    }

    return itemsByDate.entries.map((entry) {
      return AndroidWidgetItineraryDateCacheDto(
        id: _buildItineraryDateId(trip.id, entry.key),
        tripId: trip.id,
        tripName: trip.name?.isNotEmpty == true ? trip.name! : '名称未設定',
        tripPeriodLabel: _formatPeriodLabel(trip.startDate, trip.endDate),
        dateLabel: _formatDate(entry.key),
        date: entry.key,
        itineraryItems: entry.value
            .map(
              (item) => AndroidWidgetItineraryItemCacheDto(
                id: item.id,
                name: item.name,
                timeLabel: _formatTimeLabel(
                  item.startDateTime,
                  item.endDateTime,
                ),
                startDateTime: item.startDateTime,
                endDateTime: item.endDateTime,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  int _compareItineraryItems(ItineraryItemDto a, ItineraryItemDto b) {
    final startComparison = _compareNullableDateTime(
      a.startDateTime,
      b.startDateTime,
    );
    if (startComparison != 0) {
      return startComparison;
    }
    return _compareNullableDateTime(a.endDateTime, b.endDateTime);
  }

  int _compareItineraryDateCaches(
    AndroidWidgetItineraryDateCacheDto a,
    AndroidWidgetItineraryDateCacheDto b,
  ) {
    final dateComparison = a.date.compareTo(b.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return a.tripId.compareTo(b.tripId);
  }

  int _compareNullableDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return a.compareTo(b);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _buildItineraryDateId(String tripId, DateTime date) {
    return '${tripId}_${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPeriodLabel(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return '期間未設定';
    }
    if (startDate == null) {
      return '${_formatDate(endDate!)}まで';
    }
    if (endDate == null) {
      return '${_formatDate(startDate)}から';
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatTimeLabel(DateTime? startDateTime, DateTime? endDateTime) {
    if (startDateTime == null && endDateTime == null) {
      return '時刻未設定';
    }
    if (startDateTime == null) {
      return '${_formatDateTime(endDateTime!)}まで';
    }
    if (endDateTime == null) {
      return '${_formatDateTime(startDateTime)}から';
    }
    final startLabel = _formatTime(startDateTime);
    final endLabel = _isSameDate(startDateTime, endDateTime)
        ? _formatTime(endDateTime)
        : _formatDateTime(endDateTime);
    return '$startLabel - $endLabel';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime value) {
    return '${value.year}/${value.month}/${value.day}';
  }

  String _formatDateTime(DateTime value) {
    return '${value.month}/${value.day} ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}
